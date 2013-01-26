# coding : shift_jis

require 'vr/vruby'
require 'vr/vrcontrol'
require 'vr/vrcomctl'
require 'vr/vrdialog'
require 'net/http'
require 'net/https'
require 'uri'
require 'yaml'
require 'logger'
require 'open-uri'
require 'date'
require 'rexml/document'
require 'kconv'
require 'cgi'
require 'digest/sha2'
require 'win32ole'

require './const.rb'

require './book_info.rb'
require './Amazon/amazon_search.rb'
#require './Excel/excel_operator.rb'
#require './writer/excel/excel_operator.rb'
require './writer/opendocument/recorder.rb'
require './Form/isbn_input_dialog.rb'
require './Form/main_form.rb'
require './NationalDietLibrary/ndl.rb'
require './SetagayaLibrary/rent_book.rb'
require './SetagayaLibrary/setagaya_library.rb'
require './SetagayaLibrary/scraper/material_detail.rb'
require './SetagayaLibrary/scraper/menu.rb'
require './SetagayaLibrary/scraper/rent_status.rb'

Net::HTTP.version_1_2

module Librarian
  ShellExecute = Win32API.new('shell32.dll',"ShellExecute","IPPIII","I")

  class Controller
    def initialize()
      @book_list=[]
      @user_config=Constants::USER_CONFIG
      @doc_config =Constants::DOCUMENT_CONFIG
      @logger=Logger.new(Constants::LOG_DEVICE)
      @logger.level=Constants::LOG_LEVEL
    end

    def load_user_config
      @logger.debug(self.class){"load user configuration from #{@user_config}"}
      @users=YAML.load(File.open(@user_config))
      @docpath=YAML.load(File.open(@doc_config))
      @logger.debug(self.class){"success to load user configuration."}
      @logger.debug(self.class){"loaded for #{@users.collect{|x|x['name']}.join(',')}"}
    end

    def run
      @logger.debug(self.class){"Librarian starts"}
      load_user_config
      @ui=VRLocalScreen.newform(nil,nil,MainForm).create
      @ui.init_user(@users)
      @ui.controller=self
      @ui.show
      @logger.debug(self.class){"entering into GUI messageloop"}
      VRLocalScreen.messageloop
    end

    def process_search_from_isbn(isbnstr)
      @book_list.clear
      normalize(isbnstr).each do |isbn|
        book = BookInfo.new
        book.isbn = isbn
        @book_list.push book
      end
      @ui.append_log("#{@book_list.size}冊の本について詳細情報を検索します。")

      @book_list.each_with_index do |book, idx|
        @ui.append_log("#{idx+1}/#{@book_list.size}冊目の詳細情報を検索しています...。")
        book.ndc9 = search_ndc9(book.isbn)
        detail = search_amazon(book.isbn)
        book.author = detail[:Author].join(' ')
        book.manufacturer = detail[:Manufacturer].join(' ')
        book.title = detail[:Title]
      end
      @ui.append_log("詳細情報の検索を完了しました。")
      @ui.update_book_list(@book_list)
    end

    def process_search_from_library(name, uid, pwd)
      @book_list.clear
      search_setagaya_library(name,uid,pwd).each do |rent_book|
        # RentBook から BookInfo に詰め替え
        book = BookInfo.new
        book.isbn = rent_book.isbn
        book.rent_library = rent_book.library
        book.rent_due_date = rent_book.date
        @book_list.push book
      end
      @ui.append_log("#{@book_list.size}冊の本を借りています。詳細情報を検索します。")

      @book_list.each_with_index do |book, idx|
        @ui.append_log("#{idx+1}/#{@book_list.size}冊目の詳細情報を検索しています...。")
        unless book.isbn
          book.isbn = 'NO ISBN FOUND'
          book.ndc9 = ''
          book.author = 'NO ISBN FOUND'
          book.manufacturer = 'NO ISBN FOUND'
          book.title  = 'NO ISBN FOUND'
        else
          book.ndc9 = search_ndc9(book.isbn)
          detail = search_amazon(book.isbn)
          book.author = detail[:Author].join(' ')
          book.manufacturer = detail[:Manufacturer].join(' ')
          book.title = detail[:Title]
        end
      end
      @ui.append_log("詳細情報の検索を完了しました。")
      @ui.update_book_list(@book_list)
    end

    def search_setagaya_library(name, uid, pwd)
      @logger.debug(self.class){"search rent books of #{name}(#{uid}) at Setagaya Library "}
      library = SetagayaLibrary.new
      library.logger=@logger
      ret = []
      begin
        ret = library.rent_books(uid, pwd)
        @logger.debug(self.class){"number of rent books[for #{name}] is #{ret.size}"}
      rescue SocketError=>e
        @ui.append_log("世田谷区図書館との通信中にネットワーク関連のエラーが発生しました。")
        @logger.error(self.class){"世田谷区図書館との通信中にネットワーク関連のエラーが発生しました。"}
        @logger.error(self.class){e.message}
      end
      ret
    end

    def search_ndc9(isbn)
      @logger.debug(self.class){"search ndc9 for ISBN:[#{isbn}] at NDL "}
      library = NationalDietLibrary.new
      library.logger=@logger
      ndc9 = nil
      begin
        ndc9 = library.isbn2ndc9(isbn)
        @logger.debug(self.class){"NDC9[#{ndc9}] for ISBN[#{isbn}]"}
      rescue SocketError=>e
        @ui.append_log("ISBN[#{isbn}] 国会図書館との通信中にネットワーク関連のエラーが発生しました。")
        @logger.error(self.class){"ISBN[#{isbn}] 国会図書館との通信中にネットワーク関連のエラーが発生しました。"}
        @logger.error(self.class){e.message}
      rescue RuntimeError=>e
        @ui.append_log("ISBN[#{isbn}] 国会図書館での検索中にエラーが発生しました。")
        @logger.error(self.class){"ISBN[#{isbn}] 国会図書館での検索中にエラーが発生しました。"}
        @logger.error(self.class){e.message}
      end
      ndc9
    end

    def search_amazon(isbn)
      @logger.debug(self.class){"search detail info for ISBN:[#{isbn}] at Amazon "}
      searcher = AmazonSearch.new
      ret = nil
      begin
        ret = searcher.search(isbn)
      rescue SocketError=>e
        @ui.append_log("ISBN[#{isbn}] Amazonとの通信中にネットワーク関連のエラーが発生しました。")
        @logger.error(self.class){"ISBN[#{isbn}] Amazonとの通信中にネットワーク関連のエラーが発生しました。"}
        @logger.error(self.class){e.message}
      rescue RuntimeError=>e
        @ui.append_log("ISBN[#{isbn}] Amazonでの検索中にエラーが発生しました。")
        @logger.error(self.class){"ISBN[#{isbn}] Amazonでの検索中にエラーが発生しました。"}
        @logger.error(self.class){e.message}
      end
      ret
    end

    def write_record(name, book_info_list)
      @logger.debug(self.class){"writing reading marathon(excel) for #{name}"}
      Recorder.new(@docpath).record(name, book_info_list)
      GC.start
      @logger.debug(self.class){"end writing reading marathon(excel) for #{name}"}
    end

    def open_record
      if File.exist?(Constants::DOCUMENT_PATH)
        ShellExecute.call(0,"open",Constants::DOCUMENT_PATH,0,0,1)
      else
        return nil
      end
    end

    def normalize(isbnstr)
      ret=[]
      isbnstr.split("\n").each do |line|
        isbn = line.strip
        next if isbn==""
        isbn=isbn[4..-1] if isbn[0..3].upcase=='ISBN'
        isbn=isbn.scan(/([0-9a-zA-Z])/).join.upcase
        unless isbn.size == 10 or isbn.size == 13
          @logger.warn(self.class){"Inputed string [#{line}] is not valid isbn"}
          @ui.append_log("[#{line}]はISBN番号じゃないと思う。一旦無視します。")
          next
        end
        isbn = conv13to10(isbn) if isbn.size == 13
        ret.push isbn
      end
      ret.sort.uniq
    end

    def conv13to10(isbn13)
      prefix    = isbn13[0..2]      # 当面は'978'固定らしい
      country   = isbn13[3..3]      # 国コード
      publisher = isbn13[4..7]      # 出版社コード
      bookname  = isbn13[8..11]     # 書名コード
      checkdigit= isbn13[12..12]    # チェックデジット
      # ISBN-10のチェックデジットを再計算
      checkdigit = 11-(
        country[0].chr.to_i*10 +
        publisher[0].chr.to_i*9 +
        publisher[1].chr.to_i*8 +
        publisher[2].chr.to_i*7 +
        publisher[3].chr.to_i*6 +
        bookname[0].chr.to_i*5 +
        bookname[1].chr.to_i*4 +
        bookname[2].chr.to_i*3 +
        bookname[3].chr.to_i*2) % 11
      #checkdigit == 10 ?  checkdigit = 'X' : checkdigit = checkdigit.to_s
      if checkdigit == 10 
        checkdigit = 'X'
      elsif checkdigit == 11 
        checkdigit = '0'
      else
        checkdigit = checkdigit.to_s
      end
      return country+publisher+bookname+checkdigit
    end

  end
end


# tool.rb を使うときは以下をコメントアウト
Librarian::Controller.new.run


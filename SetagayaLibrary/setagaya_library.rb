# coding : shift_jis


module Librarian
  class SetagayaLibrary
    def initialize
      @https=Net::HTTP.new('libweb.city.setagaya.tokyo.jp',443)
      @https.use_ssl = true
      @https.ca_file = 'C:/home/RubyScript/etc/librarian/libweb.city.setagaya.tokyo.jp.crt'
      #@https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      @https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @https.verify_depth = 10
    end

    def logger=(logger)
      @logger=logger
    end

    def path_with_query(url_str)
        uri=URI.parse(url_str)
        "#{uri.path}?#{uri.query}"
    end

    def rent_books(uid, pass)
      rent_book_list=[]
      @https.start do |http|

        #利用者ログイン画面表示(UID/PWDのINPUT画面)
        response = http.get('/idcheck.html')
        @logger.debug(self.class){"GET 利用者ログイン画面"}

        #利用者メニュー画面取得
        data="UID=#{uid}&PASS=#{pass}"
        headers ={'Referer'=>'https://libweb.city.setagaya.tokyo.jp/idcheck.html', 'Content-Type' =>'application/x-www-form-urlencoded'}
        response = http.post('/clis/login',data,headers)
        @logger.debug(self.class){"POST 利用者メニュー画面"}

        #貸出状況照会画面取得
        scraper = Scraper::Menu.new(response.body)
        first_referer='https://libweb.city.setagaya.tokyo.jp'+path_with_query(scraper.rent_status_url)
        response = http.get(first_referer)
        @logger.debug(self.class){"GET 貸出状況照会画面[#{first_referer}]"}

        #各貸出資料詳細を順に取得
        scraper = Scraper::RentStatus.new(response.body)
        rent_book_list = retrieve_materials(http,scraper)
        # 一回目用のreferer
        headers ={'Referer'=>first_referer, 'Content-Type' =>'application/x-www-form-urlencoded'}
        @logger.debug(self.class){"retrieve_materials [1st time]"}
        while true
          if scraper.next_page?

            @logger.debug(self.class){"貸出状況照会画面 NEXTPAGE有り"}
            @logger.debug(self.class){"SID=#{scraper.sid}&TM=#{scraper.tm}&PCNT=#{scraper.pcnt}"}

            data="NEXTPAGE=TRUE&SID=#{scraper.sid}&TM=#{scraper.tm}&PCNT=#{scraper.pcnt}"
            response=http.post('https://libweb.city.setagaya.tokyo.jp/cgi-bin/logrent',data,headers)
            scraper = Scraper::RentStatus.new(response.body)
            rent_book_list = rent_book_list + retrieve_materials(http,scraper)

            # 二回目以降のrefererはこっち
            headers ={'Referer'=>"https://libweb.city.setagaya.tokyo.jp/cgi-bin/logrent", 'Content-Type' =>'application/x-www-form-urlencoded'}
          else
            @logger.debug(self.class){"貸出状況照会画面 NEXTPAGE無し"}
            break
          end
        end

      end # of https.start

      rent_book_list
    end

    def retrieve_materials(http,scraper)
      rent_book_list = []
      temp_rent_book_list = scraper.rent_materials
      isbn_list = []
      temp_rent_book_list.each do |rent_book|
        next unless rent_book.genre == '図書'
        response = http.get(path_with_query(rent_book.url))
        scraper = Scraper::MaterialDetail.new(response.body)
        rent_book.isbn = scraper.isbn

        unless isbn_list.include?(rent_book.isbn) # CD付属などでは同一ISBNが2件表示されるため
          rent_book_list.push rent_book
          @logger.debug(self.class){"rent_book_listに#{rent_book}を追加しました。"}
        end

        isbn_list.push rent_book.isbn
      end
      @logger.debug(self.class){"retrieve_materials:"+rent_book_list.join(",")}
      return rent_book_list
    end

  end
end


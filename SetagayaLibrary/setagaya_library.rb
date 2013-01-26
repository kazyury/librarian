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

        #���p�҃��O�C����ʕ\��(UID/PWD��INPUT���)
        response = http.get('/idcheck.html')
        @logger.debug(self.class){"GET ���p�҃��O�C�����"}

        #���p�҃��j���[��ʎ擾
        data="UID=#{uid}&PASS=#{pass}"
        headers ={'Referer'=>'https://libweb.city.setagaya.tokyo.jp/idcheck.html', 'Content-Type' =>'application/x-www-form-urlencoded'}
        response = http.post('/clis/login',data,headers)
        @logger.debug(self.class){"POST ���p�҃��j���[���"}

        #�ݏo�󋵏Ɖ��ʎ擾
        scraper = Scraper::Menu.new(response.body)
        first_referer='https://libweb.city.setagaya.tokyo.jp'+path_with_query(scraper.rent_status_url)
        response = http.get(first_referer)
        @logger.debug(self.class){"GET �ݏo�󋵏Ɖ���[#{first_referer}]"}

        #�e�ݏo�����ڍׂ����Ɏ擾
        scraper = Scraper::RentStatus.new(response.body)
        rent_book_list = retrieve_materials(http,scraper)
        # ���ڗp��referer
        headers ={'Referer'=>first_referer, 'Content-Type' =>'application/x-www-form-urlencoded'}
        @logger.debug(self.class){"retrieve_materials [1st time]"}
        while true
          if scraper.next_page?

            @logger.debug(self.class){"�ݏo�󋵏Ɖ��� NEXTPAGE�L��"}
            @logger.debug(self.class){"SID=#{scraper.sid}&TM=#{scraper.tm}&PCNT=#{scraper.pcnt}"}

            data="NEXTPAGE=TRUE&SID=#{scraper.sid}&TM=#{scraper.tm}&PCNT=#{scraper.pcnt}"
            response=http.post('https://libweb.city.setagaya.tokyo.jp/cgi-bin/logrent',data,headers)
            scraper = Scraper::RentStatus.new(response.body)
            rent_book_list = rent_book_list + retrieve_materials(http,scraper)

            # ���ڈȍ~��referer�͂�����
            headers ={'Referer'=>"https://libweb.city.setagaya.tokyo.jp/cgi-bin/logrent", 'Content-Type' =>'application/x-www-form-urlencoded'}
          else
            @logger.debug(self.class){"�ݏo�󋵏Ɖ��� NEXTPAGE����"}
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
        next unless rent_book.genre == '�}��'
        response = http.get(path_with_query(rent_book.url))
        scraper = Scraper::MaterialDetail.new(response.body)
        rent_book.isbn = scraper.isbn

        unless isbn_list.include?(rent_book.isbn) # CD�t���Ȃǂł͓���ISBN��2���\������邽��
          rent_book_list.push rent_book
          @logger.debug(self.class){"rent_book_list��#{rent_book}��ǉ����܂����B"}
        end

        isbn_list.push rent_book.isbn
      end
      @logger.debug(self.class){"retrieve_materials:"+rent_book_list.join(",")}
      return rent_book_list
    end

  end
end


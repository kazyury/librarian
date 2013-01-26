# coding : shift_jis

module Librarian
  module Scraper
    class Menu
      def initialize(html)
        @html=html
      end

      def rent_status_url
        @html.scan(/<LI><A HREF\="(.+?)"/).flatten.find{|url| /logrent/=~url}
      end
    end
  end
end

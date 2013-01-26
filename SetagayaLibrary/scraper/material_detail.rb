# coding : shift_jis

module Librarian
  module Scraper
    class MaterialDetail
      def initialize(html)
        @html=html.force_encoding('shift_jis')
      end

      def isbn
        isbn = @html.scan(/‚h‚r‚a‚m<\/TH><TD>(.+?)<\/TD>/m).flatten.first
        unless isbn
          return nil
        end
        isbn = isbn.strip
        isbn.delete!('\-')
        unless isbn.size==10 or isbn.size==13
          raise "isbn[#{isbn}]'s size is not 10 or 13."
        end
        isbn
      end
    end
  end
end


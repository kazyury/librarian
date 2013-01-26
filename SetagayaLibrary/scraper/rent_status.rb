# coding : shift_jis

module Librarian
  module Scraper

    class RentStatus
      def initialize(html)
        @html=html.force_encoding('shift_jis')
      end

      def flat_and_strip(ary)
        ary.flatten.collect{|x| x.strip }
      end

      def rent_materials
        ret = []
        rent_block_chunk = flat_and_strip(@html.scan(/<DIV CLASS\="PART">(.+?)<\/DIV>/m)).find{|x| /ƒ^ƒCƒgƒ‹/=~x}
        rent_list_html   = flat_and_strip(rent_block_chunk.scan(/<TR>(.+?)<\/TR>/m)).reject{|x| /TH/=~x }
        rent_list_html.each do |chunk|
          rentbook = RentBook.parse(chunk)
          ret.push rentbook
        end
        ret
      end

      def next_page?
        /<INPUT TYPE\="SUBMIT" NAME\="NEXTPAGE"/=~@html
      end

      def sid
        flat_and_strip(@html.scan(/<INPUT TYPE\="HIDDEN" NAME\="SID" VALUE\="(.+?)">/)).first
      end

      def tm
        flat_and_strip(@html.scan(/<INPUT TYPE\="HIDDEN" NAME\="TM" VALUE\="(\d+)">/)).first
      end

      def pcnt
        flat_and_strip(@html.scan(/<INPUT TYPE\="HIDDEN" NAME\="PCNT" VALUE\="(\d+)">/)).first
      end
    end
  end
end

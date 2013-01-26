# coding : shift_jis

module Librarian
  class NationalDietLibrary
    def initialize
      @http=Net::HTTP.new('iss.ndl.go.jp',80)
    end

    def logger=(logger)
      @logger=logger
    end

    def isbn2ndc9(isbn)
      #ndlc = ""
      ndc9 = ""
      @http.start do |http|
        response = http.get("/api/opensearch?isbn=#{isbn}")
        #puts response.body
        document = REXML::Document.new(response.body)
        root = document.root
        totalResults="" # 検索結果件数
        root.each_element('channel/openSearch:totalResults'){|ttl| totalResults = ttl.texts.flatten.first }
        if totalResults == '0'
          message="NDLサーチ結果が#{totalResults}件です。ISBN:#{isbn}"
          @logger.warn(self.class){message} if @logger
          # puts message unless @logger
        else
          root.each_element('channel/item/dc:subject[@xsi:type="dcndl:NDC9"]') do |subject|
            ndc9=subject.texts.flatten.join
          end
        end
      end # of http.start
      ndc9
    end

  end
end

if __FILE__ == $0
require 'net/http'
require 'rexml/document'
  library = Librarian::NationalDietLibrary.new
  p library.isbn2ndc9("4101006059")
end

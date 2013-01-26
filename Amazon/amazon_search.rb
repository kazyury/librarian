# coding : shift_jis

# these codes were copied from http://midorex.blogspot.jp/2009/06/amazon-web-with-ruby-191.html
# thanx!
module HMAC
  IPAD = "\x36" * 64
  OPAD = "\x5c" * 64
  module_function
  def sha256( key, message )
    ipad, opad = [],[]
    # バイトごとにArrayに追加
    IPAD.each_byte{|x| ipad << x }
    OPAD.each_byte{|x| opad << x}
    ikey = ipad
    okey = opad
    akey = []
    # うけとったkey もArrayへ
    key.each_byte{|x| akey << x}
    key.size.times{|i|
      ikey[i] = akey[i] ^ ipad[i]
      okey[i] = akey[i] ^ opad[i]
    }
    # コードポイントから文字列へ
    ik = ikey.pack("C*")
    ok = okey.pack("C*")
    value = Digest::SHA256.digest( ik + message )
    value = Digest::SHA256.digest( ok + value )
  end
end


module Librarian
  class AmazonSearch
    ID  = 'DummyDummyDummy'
    KEY = 'DummyDummyDummy'
    ASSOCIATE_TAG='Dummy'
    AMAZON_HOST='webservices.amazon.co.jp'
    AMAZON_PATH='/onca/xml'

    def local_utc
      t = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      escape(t)
    end

    def escape(string)
      string.gsub(/([^ a-zA-Z0-9_.-]+)/) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end.tr(' ', '+')
    end

    def search(isbn)
      uri_base = "http://" + AMAZON_HOST + AMAZON_PATH + "?"
      req = 
      [
        "Service=AWSECommerceService",
        "AssociateTag=#{ASSOCIATE_TAG}",
        "Version=2009-03-31",
        "AWSAccessKeyId=#{ID}",
        "Operation=ItemLookup",
        "SearchIndex=Books",
        "ResponseGroup=Medium",
        "IdType=ISBN",
        "ItemId=#{isbn}",
        "Timestamp=#{local_utc}"
       ].sort.join('&')
      msg = ["GET", AMAZON_HOST, AMAZON_PATH, req].join("\n")

      # 拡張モジュール1.9.1用改造版呼び出し
      hash = HMAC::sha256(KEY, msg)
      mh = [hash].pack("m").chomp 
      sig = escape(mh)

      uri = uri_base + req + "&Signature=#{sig}"

      bookinfo={:Author=>[], :Manufacturer=>[], :Title=>'', :ISBN=>isbn}
      open(uri) do |page|
        doc = REXML::Document.new(page.read.force_encoding('utf-8'))

        doc.elements.each('ItemLookupResponse/Items/Item/ItemAttributes/Author') do |elem|
          bookinfo[:Author].push elem.text.tosjis
        end

        doc.elements.each('ItemLookupResponse/Items/Item/ItemAttributes/Manufacturer') do |elem|
          bookinfo[:Manufacturer].push elem.text.tosjis
        end

        doc.elements.each('ItemLookupResponse/Items/Item/ItemAttributes/Title') do |elem|
          bookinfo[:Title]=elem.text.tosjis
        end

      end
      bookinfo
    end

  end
end



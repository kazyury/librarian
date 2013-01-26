# coding : shift_jis

module Librarian
  class RentBook
    def RentBook.parse(html_chunk)
      genre, book, ident, library, date = html_chunk.scan(/<TD>(.+?)<\/TD>/m).flatten
      url = book.scan(/A HREF="(.+?)"/).flatten.first
      title=book.scan(/">(.+?)<\/A>/).flatten.first
      ret = RentBook.new
      ret.genre = genre
      ret.title = title
      ret.url   = url
      ret.ident = ident
      ret.library = library
      ret.date = date
      ret
    end
    attr_accessor :genre, :title, :url, :ident, :library, :date, :isbn
  end
end

# coding : shift_jis

module ExcelConst; end

module Librarian
  class ExcelOperator
    def record(sheetname, book_info_list)
      xls=WIN32OLE.new('Excel.Application')
#      WIN32OLE.const_load(xls, ExcelConst)
      xls.visible=false
      xls.displayAlerts=false

      fso=WIN32OLE.new('Scripting.FileSystemObject')
      outfile=fso.GetAbsolutePathName(Constants::EXCEL_PATH)
      book=xls.Workbooks.open(outfile)

      p "1:#{sheetname}"
      sheet=book.Worksheets.Item(sheetname)
      firstline=0
      p "sheet is #{sheet}"

      p "2"
        4.upto(65536) do |idx|
          unless sheet.Range("D#{idx}").Value
            firstline=idx
            break
          end
        end
      p "firstline is #{firstline}"

      p "3"
      begin
        book_info_list.each do |book_info|
          # D列：タイトル
          # E列：著者(発行者)
          # I列：ISBN
          # J列：NDC9
          sheet.range("D#{firstline}").value = "#{book_info.title}"
          sheet.range("E#{firstline}").value = "#{book_info.author}(#{book_info.manufacturer})"
          sheet.range("I#{firstline}").value = "#{book_info.isbn}"
          sheet.range("J#{firstline}").value = "#{book_info.ndc9}"
          firstline+=1
        end
        p "3"
        p "respond to save?"
        p book.respond_to?(:save)
        book.Save
      ensure
        p "respond to close?"
        p book.respond_to?(:close)
        book.close({"savechanges"=>false})
#        xls.Workbooks.Close
        xls.Quit
        WIN32OLE.ole_free xls
        GC.start
      end
    end
  end
end


# coding : shift_jis

require 'win32ole'

module Librarian
  class Recorder

    def initialize(config)
      @uri = config['uri']
    end

    def record(sheetname, book_info_list)
      serviceManager = WIN32OLE.new("com.sun.star.ServiceManager")
      desktop = serviceManager.createInstance("com.sun.star.frame.Desktop")
      _opt = {"Hidden"=>true}.inject(opts = []) {|x,y|
        opt = serviceManager.Bridge_GetStruct("com.sun.star.beans.PropertyValue")
        opt.Name = y[0]
        opt.Value = y[1]
        x << opt
      }

      document = desktop.loadComponentFromURL(@uri,"_hidden", 0, _opt)
      document.addActionLock()
      sheets = document.getSheets()
      sheet  = sheets.getByName(sheetname)

      firstline=0
      4.upto(65536) do |idx|
        cell = sheet.getCellRangeByName("D#{idx}")
        if cell.string == ""
          firstline=idx
          break
        end
      end
      p "firstline is #{firstline}"

      begin
        book_info_list.each do |book_info|
          # D列：タイトル
          # E列：著者(発行者)
          # I列：ISBN
          # J列：NDC9
          sheet.getCellRangeByName("D#{firstline}").string = "#{book_info.title}"
          sheet.getCellRangeByName("E#{firstline}").string = "#{book_info.author}(#{book_info.manufacturer})"
          sheet.getCellRangeByName("I#{firstline}").string = "#{book_info.isbn}"
          sheet.getCellRangeByName("J#{firstline}").string = "#{book_info.ndc9}"
          firstline+=1
        end
        document.store()
      ensure
        document.close(true)
        document = nil
        desktop.Terminate if desktop
        desktop = nil
        serviceManager = nil
      end
    end
  end
end



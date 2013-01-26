# coding : shift_jis

module Librarian
class MainForm < VRForm

  def construct
    self.caption = '読書マラソン　バージョンアップ'
    self.move(317,122,485,563)

    addControl(VRCombobox,'namebox',"",8,8,224,120)

    addControl(VRStatic,'static1',"どうする？",8,40,224,24)
    addControl(VRRadiobutton,'lib_search_rb',"図書館で借りている本から選ぶ",8,72,256,24)
    addControl(VRRadiobutton,'isbn_input_rb',"自分でISBNを入力",264,72,224,24)

    addControl(VRStatic,'static2',"本の検索結果",8,104,96,24)
    addControl(VRStatic,'static3',"読書マラソンに転記する本を選んで、「転記」ボタンを押してね。Ctrlボタンを押しながら選ぶと複数選べます。",8,352,456,40)

    addControl(VRListview,'book_list_view',"listView1",8,136,456,208)
    @book_list_view.addColumn("タイトル",120)
    @book_list_view.addColumn("返却日",120)
    @book_list_view.addColumn("著者等",120)
    @book_list_view.addColumn("発行元",120)
    @book_list_view.addColumn("ISBN",120)
    @book_list_view.addColumn("分類",120)
    @book_list_view.addColumn("図書館",120)

    addControl(VRButton,'write_pb',"この本を読書マラソンに転記",8,400,216,40)
    addControl(VRButton,'open_pb',"読書マラソンを開く",232,400,232,40)

    addControl(VRText,'log_text',"",8,448,456,80,WStyle::WS_VSCROLL)
    @log_text.readonly=true
  end 

  def init_user(users)
    @users=users
    usernames = @users.map{|x| x["name"]}
    @namebox.setListStrings ["--誰の？--"]+usernames
    @namebox.select(0)
  end

  def controller=(controller)
    @controller = controller
  end

  def append_log(message)
    @log_text.text=message+"\n"+@log_text.text.force_encoding("shift_jis")
    @log_text.refresh
  end

  def user_selected?
    @namebox.selectedString != 0
  end

  def selected_user
    @users[@namebox.selectedString-1] # magic word -1 => "--誰の?--"
  end

  def lib_search_rb_clicked
    unless user_selected?
      messageBox("誰の分にするか最初に選んでね")
      @lib_search_rb.check(false)
      return
    end
    append_log("#{selected_user['name'].force_encoding('shift_jis')}が世田谷区の図書館で借りている本を検索します。")
    @controller.process_search_from_library(selected_user["name"],selected_user["uid"],selected_user["pwd"])
  end

  def isbn_input_rb_clicked
    unless user_selected?
      messageBox("誰の分にするか最初に選んでね")
      @isbn_input_rb.check(false)
      return
    end
    ret = VRLocalScreen.modalform(self,nil,IsbnInputDialog)
    if ret
      @controller.process_search_from_isbn(ret)
    end
  end

  def update_book_list(book_list)
    @book_list_view.clearItems
    @book_list = book_list
    @book_list.each do |book|
      @book_list_view.addItem([book.title, book.rent_due_date, book.author, book.manufacturer, book.isbn, book.ndc9, book.rent_library])
    end
  end

  def write_pb_clicked
    begin
      @open_pb.enabled=false
      processing_books=[]
      @book_list_view.eachSelectedItems do |idx|
        processing_books.push @book_list[idx]
      end
      if processing_books.empty?
        messageBox("転記する本を選んでね")
        return
      end
      append_log("読書マラソンへの転記を開始します。")
      @controller.write_record(selected_user["name"], processing_books)
      append_log("読書マラソンへの転記を終えました。")
      messageBox("転記が完了しました。")
    ensure
      @open_pb.enabled=true
    end
  end

  def open_pb_clicked
    unless @controller.open_record
      append_log("#{path}が見つかりません。文句を言ってください。") 
    end
  end

end
end


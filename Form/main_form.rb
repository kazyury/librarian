# coding : shift_jis

module Librarian
class MainForm < VRForm

  def construct
    self.caption = '�Ǐ��}���\���@�o�[�W�����A�b�v'
    self.move(317,122,485,563)

    addControl(VRCombobox,'namebox',"",8,8,224,120)

    addControl(VRStatic,'static1',"�ǂ�����H",8,40,224,24)
    addControl(VRRadiobutton,'lib_search_rb',"�}���قŎ؂�Ă���{����I��",8,72,256,24)
    addControl(VRRadiobutton,'isbn_input_rb',"������ISBN�����",264,72,224,24)

    addControl(VRStatic,'static2',"�{�̌�������",8,104,96,24)
    addControl(VRStatic,'static3',"�Ǐ��}���\���ɓ]�L����{��I��ŁA�u�]�L�v�{�^���������ĂˁBCtrl�{�^���������Ȃ���I�Ԃƕ����I�ׂ܂��B",8,352,456,40)

    addControl(VRListview,'book_list_view',"listView1",8,136,456,208)
    @book_list_view.addColumn("�^�C�g��",120)
    @book_list_view.addColumn("�ԋp��",120)
    @book_list_view.addColumn("���ғ�",120)
    @book_list_view.addColumn("���s��",120)
    @book_list_view.addColumn("ISBN",120)
    @book_list_view.addColumn("����",120)
    @book_list_view.addColumn("�}����",120)

    addControl(VRButton,'write_pb',"���̖{��Ǐ��}���\���ɓ]�L",8,400,216,40)
    addControl(VRButton,'open_pb',"�Ǐ��}���\�����J��",232,400,232,40)

    addControl(VRText,'log_text',"",8,448,456,80,WStyle::WS_VSCROLL)
    @log_text.readonly=true
  end 

  def init_user(users)
    @users=users
    usernames = @users.map{|x| x["name"]}
    @namebox.setListStrings ["--�N�́H--"]+usernames
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
    @users[@namebox.selectedString-1] # magic word -1 => "--�N��?--"
  end

  def lib_search_rb_clicked
    unless user_selected?
      messageBox("�N�̕��ɂ��邩�ŏ��ɑI��ł�")
      @lib_search_rb.check(false)
      return
    end
    append_log("#{selected_user['name'].force_encoding('shift_jis')}�����c�J��̐}���قŎ؂�Ă���{���������܂��B")
    @controller.process_search_from_library(selected_user["name"],selected_user["uid"],selected_user["pwd"])
  end

  def isbn_input_rb_clicked
    unless user_selected?
      messageBox("�N�̕��ɂ��邩�ŏ��ɑI��ł�")
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
        messageBox("�]�L����{��I��ł�")
        return
      end
      append_log("�Ǐ��}���\���ւ̓]�L���J�n���܂��B")
      @controller.write_record(selected_user["name"], processing_books)
      append_log("�Ǐ��}���\���ւ̓]�L���I���܂����B")
      messageBox("�]�L���������܂����B")
    ensure
      @open_pb.enabled=true
    end
  end

  def open_pb_clicked
    unless @controller.open_record
      append_log("#{path}��������܂���B����������Ă��������B") 
    end
  end

end
end


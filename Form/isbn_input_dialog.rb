# coding : shift_jis

module Librarian
class IsbnInputDialog < VRModalDialog
  include VRContainersSet
  def construct
    self.caption = 'ISBN‚ð“ü—Í‚µ‚æ‚¤'
    self.move(317,124,328,400)
    addControl(VRText,'text1',"",8,40,304,280,WStyle::ES_WANTRETURN)
    addControl(VRButton,'ok_pb',"OK",8,328,80,24)
    addControl(VRButton,'cancel_pb',"ƒLƒƒƒ“ƒZƒ‹",232,328,80,24)
    addControl(VRStatic,'static1',"ISBN”Ô†‚ð“ü—Í‚µ‚Ä‚ËB",8,8,304,24)
  end 

  def ok_pb_clicked
    self.close(@text1.text)
  end

  def cancel_pb_clicked
    self.close(nil)
  end

end
end

##__END_OF_FORMDESIGNER__

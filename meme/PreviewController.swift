

import UIKit
import Alamofire

class PreviewController: UIViewController {

    @IBOutlet weak var photo: UIImageView!
    var image: UIImage!
    let popup: DefaultPopupView = UINib(nibName: "DefaultPopupView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as! DefaultPopupView
    
    var retake = false
    var fail_reg_no = ""
    var cariCnt = 0
    var point = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        photo.image = self.image
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButton_TouchUpInside(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButton_TouchUpInside(_ sender: UIButton) {
        showDialog()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToMain" {
            let previewVC = segue.destination as! MainViewController
            previewVC.uploadSuccess = true

        }
    }
    
    func showDialog(){
        
        // 팝업뷰 배경색(회색)
        let viewColor = UIColor.black
        // 반튜명 부모뷰
        popup.backgroundColor = viewColor.withAlphaComponent(0.4)
        popup.frame = self.view.frame // 팝업뷰를 화면크기에 맞추기
        // 팝업창 배경색 (흰색)
        let baseViewColor = UIColor.white
        // 팝업배경
        //popup.baseView.backgroundColor = baseViewColor.withAlphaComponent(0.8)
        popup.baseView.backgroundColor = baseViewColor
        // 팝업테두리 둥글게
        popup.baseView.layer.cornerRadius = 9.0
        
        // 처음 캐리커처를 만들때는 무료로 생성해야하기때문에 재촬영을 true로 설정해준다.
        
        popup.oneBtnView.isHidden = true
        popup.twoBtnView.isHidden = false
        popup.rightBtnClick.setTitle("신청", for: .normal)
        if self.retake {
            popup.title.text = "이모티콘 생성"
            popup.content.text = "해당 사진으로 이모티콘을 생성하시겠습니까?"
        }else if cariCnt == 0{
            popup.title.text = "포인트 결제"
            //popup.content.text = "1회는 무료입니다"
            let str = "1회는 무료입니다"
            let message = NSMutableAttributedString(string: str)
            message.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.blue, range: (str as NSString).range(of: str))
            // set attributed text on a UILabel
            popup.content.attributedText = message
        }else{
            popup.title.text = "포인트 결제"
            //popup.content.text = "3,000 포인트\n(보유)"
            let pointText = "3,000포인트"
            let formatter : NumberFormatter = NumberFormatter()
            formatter.numberStyle = NumberFormatter.Style.decimal
            formatter.groupingSeparator = ","
            formatter.groupingSize = 3
            let price : String = formatter.string(from: point as NSNumber)!
            
            let str = "3,000포인트\n(보유 \(price)P)"
            let userPointText = "(보유 \(price)P)"
            let message = NSMutableAttributedString(string: str)
            message.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "HelveticaNeue-Bold", size: 25)!, range: (str as NSString).range(of: pointText))
            message.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.black, range: (str as NSString).range(of: pointText))
            message.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(hex: "E2A6A1"), range: (str as NSString).range(of: userPointText))
            
            // set attributd text on a UILabel
            popup.content.attributedText = message
        }
        popup.leftBtnClick.addTarget(self, action:#selector(self.leftBtnClicked), for: .touchUpInside)
        popup.rightBtnClick.addTarget(self, action:#selector(self.rightBtnClicked), for: .touchUpInside)
        self.view.addSubview(popup)
        
        func buttonClicked() {
            print("Button Clicked")
        }
        self.view.addSubview(popup)
    }
    @objc func leftBtnClicked(_ sender : UIButton){
        popup.removeFromSuperview()
    }
    @objc func rightBtnClicked(_ sender : UIButton){
        fileUpload()
        popup.removeFromSuperview()
    }
    
    func fileUpload(){
        let fileName = ShardUtil.makeFile();
        guard let imageData = UIImageJPEGRepresentation(image, 0.8)  else{
            print("not JPEG represention of UIIage")
            return
        }
        let url = "\(HTTPUtil.IP)/app/caricature/upload"
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(imageData, withName: "img_file", fileName: fileName, mimeType: "image/jpeg")
            
            if self.cariCnt == 0 {
                multipartFormData.append("1".data(using: String.Encoding.utf8)!, withName: "freeCaricature")
            }else{
                multipartFormData.append("0".data(using: String.Encoding.utf8)!, withName: "freeCaricature")
            }
            if self.retake {
                multipartFormData.append("1".data(using: String.Encoding.utf8)!, withName: "retake")
            }else{
                multipartFormData.append("0".data(using: String.Encoding.utf8)!, withName: "retake")
            }
            
            if self.fail_reg_no != "0" {
                multipartFormData.append(self.fail_reg_no.data(using: String.Encoding.utf8)!, withName: "fail_reg_no")
            }
            multipartFormData.append("0".data(using: String.Encoding.utf8)!, withName: "freeCaricature")
            
            let ud = UserDefaults.standard
            let id = ud.string(forKey: "id") ?? ""
            multipartFormData.append(id.data(using: String.Encoding.utf8)!, withName: "reg_id")
        }, to: url) { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON(completionHandler: { (response) in
                    if let JSON = response.result.value as? [String: Any]{
                        print(JSON)
                        let result : Bool = JSON["result"] as! Bool
                        if result {
                            self.performSegue(withIdentifier: "unwindToMain", sender: self)
                        }
                        else{
                        
                        }
                    }
                })
            case .failure(let encodingError):
                print("encodingError : \(encodingError)")
            }
        }
    }
}



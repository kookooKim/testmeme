
import UIKit
import WebKit
import Alamofire
import AVFoundation
import StoreKit

class MainViewController: UIViewController, WKUIDelegate, UIScrollViewDelegate, TAPageControlDelegate, AVAudioRecorderDelegate, SKPaymentTransactionObserver, SKProductsRequestDelegate{
    
    
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var WebViewController: UIView!
    @IBOutlet weak var MenuController: UIView!
    @IBOutlet weak var BennerController: UIView!
    
    //스크롤 이미지 메뉴
    @IBOutlet weak var scrollView: UIScrollView!
    
    var scrollimage = NSArray()
    var index = 0
    var customPageControl2 = TAPageControl()
    var timer = Timer()
    //end스크롤 이미지 메뉴
    
    var activityIndicator = UIActivityIndicatorView()  //로딩뷰
    var dialogType = 0
    var uploadSuccess = false
    
    
    //인앱 결제
    var product:SKProduct?
    var productID = ""
    
    //스플래쉬에서 로그인 넘어올때
    var isAutoLogin = false
    var id = ""
    var passwd = ""
    
    //카메라 및 앨범관련
    var fileName = ""
    var imageData : Data?

    //이전 페이지 저장 변수
    var prevPage = 1
    let popup: DefaultPopupView = UINib(nibName: "DefaultPopupView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as! DefaultPopupView
    
    //음성녹음 체크
    var isRecorded = false
    var recordFile : Data?
    
    //카메라 재촬영시
    public var retakeCamera = false
    public var fail_reg_no = "0"
    
    //음성 녹음 관련 변수 선언
    var audioPlayer: AVAudioPlayer?
    var audioRecorder: AVAudioRecorder?
    var audioBaseRecorder : AVAudioRecorder?
    var fileUrl : URL?
    
    var audioRatePitch: AVAudioUnitTimePitch!
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var audioFile: AVAudioFile!
    var firstRecord = true
    var isReRecordState = false
    var isPlayState = false
    var isVoiceModule = "0"
    var isCancel = false
    var record = false
    
    //현재까지 요청한 캐리커처 갯수
    var cariCnt = 0
    //현재 포인트
    var point = 0
    
    //앱 처음 시작 체크
    var isStart = true
    
    //녹음 리로드 체크
    var reloadCheck = true
    
    //세로고정
    private var _orientations = UIInterfaceOrientationMask.portrait
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get { return self._orientations }
        set { self._orientations = newValue }
    }
    
    
    @IBAction func gotoMain(_ sender: UIStoryboardSegue){
        if uploadSuccess {
            let message :NSDictionary = [
                "title" : "신청완료",
                "contents" : "24시간 이내에 얼굴이 완성되면 알림으로 알려드립니다",
                "type" : 0,
                "popupType" : 0
            ]
            showDialog(message: message)
            webView.evaluateJavaScript("javascript:location.reload();", completionHandler: nil)
        }else{
            
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print()
        //스플래쉬에서 로그인 넘어올때
        isAutoLogin = MemeExternData.sharedInstance.isAutoLogin
        id = MemeExternData.sharedInstance.id
        passwd = MemeExternData.sharedInstance.passwd
        
        let contentController = WKUserContentController()
        let controllArray : [String] = ["showDialog","setFloattingBtn","setAutoLogin","myPhoneNumber","setProfileImage","sendProfile","versionCheck","faceDataInit","setFaceImage","getFaceImage","setPrevPage","getPrevPage","shareImage","downloadEmoticon","setHairImage","getHairImage","retakeCamera","makeEmoticon","makeRecBtn","voiceModuleBtn","removeRecorder","cariCntPointCheck","recReload","sendPushKey","inAppBilling","showFirstPopup","setMainAdToday"]
        for content in controllArray {
            contentController.add(self, name: content)
        }
        
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        webView = WKWebView(frame: self.webView.frame, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        //webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
       
        self.WebViewController.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            let safeArea = self.view.safeAreaLayoutGuide
            webView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: MenuController.bottomAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor).isActive = true
        }
        else{
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            webView.topAnchor.constraint(equalTo: MenuController.bottomAnchor).isActive = true
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            webView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor).isActive = true
        }
        
        
        sideMenu()
        
        //인앱결제
        SKPaymentQueue.default().add(self)
        
        //오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        }catch{
            //print("AudioSession Error ==> \()")
        }
        //오디오 출력 스피커 라우팅 해야함(소리가 작기떄문에)
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch _ {}
        
        
        if isAutoLogin {
            self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/appmember/auto_login?id=\(id)&passwd=\(passwd)")
        }else{
            self.WebViewLoad( strurl: "\(HTTPUtil.IP)\(HTTPUtil.MAIN)")

        }
        
        //스크롤뷰 설정
        self.scrollimage = [ "splashgif01.png" , "splashgif02.png" , "splashgif03.png" ]
        settingScrollView()
        
    }
    
    func settingScrollView(){
        //스크롤뷰에 이미지를 셋팅
        for i in 0..<self.scrollimage.count {
            print(i)
            let xPos = self.view.frame.size.width * CGFloat(i)
            let imageView = UIImageView(frame: CGRect(x:xPos, y: 0, width: self.view.frame.width, height:
                self.scrollView.frame.size.height))
            imageView.contentMode = .scaleAspectFill
            imageView.image = UIImage(named: self.scrollimage[i] as! String )
            self.scrollView.addSubview(imageView)
        }
        self.scrollView.delegate = self
        index=0
        
        self.customPageControl2 = TAPageControl(frame: CGRect(x: 20, y:
            self.scrollView.frame.origin.y+self.scrollView.frame.size.height, width: self.scrollView.frame.size.width,
                                                                              height: 40 ))
        self.customPageControl2.delegate = self
        self.customPageControl2.numberOfPages = self.scrollimage.count
        //스크롤뷰 하단의 점표시하는코드
        self.customPageControl2.dotSize = CGSize(width: 20, height: 20)
        self.scrollView.contentSize = CGSize(width: self.view.frame.size.width * CGFloat(self.scrollimage.count), height:
            self.scrollView.frame.size.height)
        //self.view.addSubview(self.customPageControl2)
    }
    
    override func viewDidAppear( _ animated: Bool ) {
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(runImages), userInfo:nil,
                                     repeats: true )
    }
    
    override func viewDidDisappear( _ animated: Bool ){
        timer.invalidate()
    }
    
    @objc func runImages(){
        self.customPageControl2.currentPage = index
        if index == self.scrollimage.count - 1 {
            self.index=0
        }
        else{
            self.index = self.index + 1
        }
        self.taPageControl(self.customPageControl2, didSelectPageAt: self.index)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = scrollView.contentOffset.x / scrollView.frame.size.width
        self.customPageControl2.currentPage = Int(pageIndex)
        index = Int(pageIndex)
    }
    
    func  taPageControl(_ pageControl: TAPageControl!, didSelectPageAt currentIndex: Int) {
        index = currentIndex
         self.scrollView.scrollRectToVisible(CGRect(x: self.view.frame.size.width * CGFloat(currentIndex), y: 0, width:
            self.view.frame.width, height: self.scrollView.frame.size.height), animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
//        var viewBounds : CGRect = self.view.bounds
//        viewBounds.origin.y = 20
//        viewBounds.size.height = viewBounds.size.height - 20
//        self.webView.frame = viewBounds
        
    }
    
    func sideMenu()
    {
        if revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            revealViewController()?.rearViewRevealWidth = 275
            revealViewController()?.rightViewRevealWidth = 160
            
           //view.addGestureRecognizer(self.revealViewController()?.panGestureRecognizer())
        }
    }
    
    func WebViewLoad( strurl: String)
    {
        let url = URL(string: strurl)
        print(url)
        var myRequest = URLRequest(url: url!)
        var cookies = HTTPCookie.requestHeaderFields(with: HTTPCookieStorage.shared.cookies(for: myRequest.url!)!)
        if let value = cookies["Cookie"] {
            myRequest.addValue(value, forHTTPHeaderField: "Cookie")
            
        }
        
        self.webView.load(myRequest)
    }
    
    // 버튼 타이틀 컬러 바꾸기
    //buttonName.setTitleColor(UIColor.blackColor(), forState: .Normal)
    
    //NEW
    @IBAction func NewButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=0")
    }
    //기쁨
    @IBAction func HappinessButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=1")
        
    }
    //짜증
    @IBAction func AnnoyanceButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=2")
    }
    //행복
    @IBAction func HappyButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=3")
    }
    //슬픔
    @IBAction func SadnessButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=4")
    }
    //삐짐
    @IBAction func CrookedButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=5")
    }
    //귀여움
    @IBAction func DearnessButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=6")
    }
    //사랑
    @IBAction func LoveButtonClick(_ sender: Any) {
        self.WebViewLoad( strurl: "\(HTTPUtil.IP)/app/index?type=7")
    }
    
    //앨범에서 가져오기
    func uploadFromAlbum(){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    //사진 찍기
    func uploadFromCamera(){
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    //파일 업로드(mp4 or gif)
    func recordFileUpload(record : Bool){
        if record {
            let url = "\(HTTPUtil.IP)/app/emoticon/upload_record_file"
            if fileUrl == nil {
                let message :NSDictionary = [
                    "title" : "알림",
                    "contents" : "음성 녹음을 먼저 실행해주시기 바랍니다.",
                    "type" : 0,
                    "popupType" : 0
                ]
                showDialog(message: message)
                return
            }
            let dataFile = NSData(contentsOf: fileUrl!)
            Alamofire.upload(multipartFormData: { (multipartFormData) in
                multipartFormData.append(dataFile as! Data, withName: "record_file", fileName: "record_file.wav", mimeType: "audio/wav")
            }, to: url) { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON(completionHandler: { (response) in
                        if let JSON = response.result.value as? [String: Any]{
                            print("JSON : \(JSON)")
                            let result : Bool = JSON["result"] as! Bool
                            if result {
                                let audio_path = JSON["audio_path"] as! String
                                self.webView.evaluateJavaScript("$('#emoticon-form').find('input[name=rec_file]').val('\(audio_path)');", completionHandler: nil)
                                self.webView.evaluateJavaScript("javascript:emoticonSave();", completionHandler: nil)
                            }
                            else{
                                let message :NSDictionary = [
                                    "title" : "실패",
                                    "contents" : "음성파일 업로드에 실패하였습니다.",
                                    "type" : 0,
                                    "popupType" : 0
                                ]
                                self.showDialog(message: message)
                            }
                        }
                    })
                case .failure(let encodingError):
                    print("encodingError : \(encodingError)")
                }
            }
        }else{
            //gif파일
            print("emoticonSave !!!")
            webView.evaluateJavaScript("javascript:emoticonSave()", completionHandler: nil)
        }
        
    }
    
    //프로파일 이미지 업로드
    func profileUpdate(message : NSDictionary){
        var passwdChange = false;
        var passwdString = ""
        
        let url = "\(HTTPUtil.IP)/app/appmember/member_modify"
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for data in message {
                if data.key as! String == "passwd" {
                    if data.value as! String != "" {
                        passwdChange = true
                        passwdString = data.value as! String
                    }else{
                        passwdChange = false
                    }
                }
                multipartFormData.append((data.value as! String).data(using: String.Encoding.utf8)!, withName: data.key as! String)
            }
            if(self.imageData != nil){
                multipartFormData.append(self.imageData!, withName: "img_file", fileName: self.fileName, mimeType: "image/jpeg")
                multipartFormData.append("Y".data(using: String.Encoding.utf8)!, withName: "img_yn")
            }else{
                multipartFormData.append("N".data(using: String.Encoding.utf8)!, withName: "img_yn")
            }
            
        }, to: url) { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON(completionHandler: { (response) in
                    if let JSON = response.result.value as? [String: Any]{
                        let result : Bool = JSON["result"] as! Bool
                        if result {
                            self.webView.evaluateJavaScript("javascript:location.replace('/app/index')", completionHandler: nil)
                            self.imageData = nil
                            if passwdChange {
                                let ud = UserDefaults.standard
                                ud.set(passwdString, forKey: "passwd")
                            }
                            self.activityIndicator.removeFromSuperview()
                            self.activityIndicator.stopAnimating()
                        }
                        else{
                            self.webView.evaluateJavaScript("javascript:location.reload();", completionHandler: nil);
                            self.activityIndicator.removeFromSuperview()
                            self.activityIndicator.stopAnimating()
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    }
                })
            case .failure(let encodingError):
                self.activityIndicator.removeFromSuperview()
                self.activityIndicator.stopAnimating()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                print("encodingError : \(encodingError)")
            }
        }
     
    }
    
    
    func showDialog(message : NSDictionary){
        
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
        
        guard let title = message.value(forKey: "title") as? String, let contents = message.value(forKey: "contents") as? String else{return}
        guard let type : Int = message.value(forKey: "type") as? Int else{return}
        guard let popupType : Int = message.value(forKey: "popupType") as? Int else{return}
        
        if popupType == 0{
            popup.oneBtnView.isHidden = false
            popup.twoBtnView.isHidden = true
        }else{
            popup.oneBtnView.isHidden = true
            popup.twoBtnView.isHidden = false
        }
        
        dialogType = type
        popup.title.text = title
        popup.content.text = contents
        
        switch dialogType {
        case 14:
            popup.title.textColor = UIColor.red
            popup.leftBtnClick.setTitleColor(UIColor.red, for: .normal)
            popup.leftBtnClick.setTitle("초기화", for: .normal)
            popup.rightBtnClick.setTitle("취소", for: .normal)
        case 17:
            popup.rightBtnClick.setTitle("신청", for: .normal)
        case 23:
            popup.leftBtnClick.setTitle("취소", for: .normal)
            popup.rightBtnClick.setTitle("삭제", for: .normal)
            popup.rightBtnClick.setTitleColor(UIColor.red, for: .normal)
        case 24:
            popup.rightBtnClick.setTitle("신청", for: .normal)
            let color = UIColor(hex: "2287FE")
            popup.content.textColor = color
        case 25:
            popup.rightBtnClick.setTitle("신청", for: .normal)
            // create attributed string
//            let myString = contents
//            var myRange = NSRange(location: 12, length: 8)
//            let attributes = [NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-Bold", size: 25)!,
//                              NSAttributedStringKey.foregroundColor: UIColor.black]
//            let myAttrString = NSAttributedString(string: contents, attributes: attributes)
            
            let pointText = "3,000포인트"
            let str = contents
            let message = NSMutableAttributedString(string: str)
            message.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "HelveticaNeue-Bold", size: 25)!, range: (str as NSString).range(of: pointText))
            message.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.black, range: (str as NSString).range(of: pointText))
            // set attributed text on a UILabel
            popup.content.attributedText = message
            
        default:
            popup.leftBtnClick.setTitle("취소", for: .normal)
            popup.rightBtnClick.setTitle("확인", for: .normal)
            let color = UIColor(hex: "4E4967")
            let contentColor = UIColor(hex: "666666")
            popup.rightBtnClick.setTitleColor(color, for: .normal)
            popup.content.textColor = contentColor
        }
        
        popup.okBtnClick.addTarget(self, action:#selector(self.okBtnClicked), for: .touchUpInside)
        popup.leftBtnClick.addTarget(self, action:#selector(self.leftBtnClicked), for: .touchUpInside)
        popup.rightBtnClick.addTarget(self, action:#selector(self.rightBtnClicked), for: .touchUpInside)
        self.view.addSubview(popup)
        
        func buttonClicked() {
            print("Button Clicked")
        }
        self.view.addSubview(popup)
    }
    
    
    //        type : 0 -> 일반알람
    //               1 -> 갤러리 삭제료완료 , 캐리커처 저장
    //               2 -> 문의 등록완료
    //               3 -> 히스토리 빽
    //              11 -> 휴면 계정 해제
    //              12 -> 문의사항 전송
    //              13-> 포인트 선물
    //              14-> 앱초기화
    //              15-> 로그아웃
    //              16-> 아이콘 구매
    //              17-> 캐리커처 제작요청
    //              18-> 캐리커처 삭제
    //              19-> 포인트 구매
    //              20-> 이동시 작업중인 정보가 없어집니다. 문구
    //              21-> 포인트를 사용하여 이모티콘 저장
    //              22-> 뷰티로 꾸민 얼굴 저장후 로직
    //              23-> 갤러리에서 이모티콘 삭제
    //              24-> 얼굴제작 무료 신청
    //              25-> 얼굴제작 유료 신청
    
    @objc func okBtnClicked(_ sender : UIButton){
        switch dialogType {
        case 0:
            popup.removeFromSuperview()
            self.activityIndicator.removeFromSuperview()
            self.activityIndicator.stopAnimating()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        case 1:
            webView.evaluateJavaScript("javascript:location.replace('/app/index');", completionHandler: nil)
            popup.removeFromSuperview()
        case 2:
            webView.evaluateJavaScript("javascript:location.reload();", completionHandler: nil)
            popup.removeFromSuperview()
        case 3:
            webView.evaluateJavaScript("javascript:history.back();", completionHandler: nil)
            popup.removeFromSuperview();
        case 11:
            popup.removeFromSuperview()
        case 12:
            popup.removeFromSuperview()
        default:
            popup.removeFromSuperview()
            break
        }
    }
    @objc func leftBtnClicked(_ sender : UIButton){
        switch dialogType {
        case 0:
            popup.removeFromSuperview()
        case 14:
            webView.evaluateJavaScript("javascript:resetApp();", completionHandler: nil)
            popup.removeFromSuperview()
        default:
            popup.removeFromSuperview()
            break
        }
    }
    @objc func rightBtnClicked(_ sender : UIButton){
        switch dialogType {
        case 0:
            popup.removeFromSuperview()
        case 12:
            webView.evaluateJavaScript("javascript:sendDataForm();", completionHandler: nil)
            popup.removeFromSuperview()
        case 13:
            webView.evaluateJavaScript("javascript:sendPoint();", completionHandler: nil)
            popup.removeFromSuperview()
        case 15:
            ShardUtil.setLogout()
            webView.evaluateJavaScript("javascript:location.href='/app/j_spring_security_logout'", completionHandler: nil)
            popup.removeFromSuperview()
        case 16:
            webView.evaluateJavaScript("javascript:emoticonBuy()", completionHandler: nil)
            popup.removeFromSuperview()
        case 17:
            var message : NSDictionary = [:]
            if cariCnt != 0 {
                message = [
                    "title" : "얼굴제작신청",
                    "contents" : "2회부터는 유료입니다.\n3,000포인트",
                    "type" : 25,
                    "popupType" : 1
                ]
            }else{
                message = [
                    "title" : "얼굴제작 신청",
                    "contents" : "1회는 무료입니다",
                    "type" : 24,
                    "popupType" : 1
                ]
            }
            showDialog(message: message)
            
//            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "CustomCamera") as? CustomCameraController {
//                self.present(vc, animated: true, completion: nil)
//            }
//            popup.removeFromSuperview()
        case 18:
            webView.evaluateJavaScript("javascript:removeCaricature()", completionHandler: nil)
            popup.removeFromSuperview()
        case 19:
            webView.evaluateJavaScript("javascript:buyPoint()", completionHandler: nil)
            popup.removeFromSuperview()
        case 20:
            //녹음레코더 삭제
            if audioRecorder != nil {
               audioRecorder = nil
                reloadCheck = true
            }
            webView.evaluateJavaScript("javascript:location.replace('/app/index');", completionHandler: nil)
            popup.removeFromSuperview()
        case 21:
            if record {
                recordFileUpload(record: true)
            }else{
                recordFileUpload(record: false)
            }
            popup.removeFromSuperview()
        case 22:
            webView.evaluateJavaScript("javascript:saveBeauty();", completionHandler: nil)
            popup.removeFromSuperview()
        case 23:
            webView.evaluateJavaScript("javascript:deleteGallery();", completionHandler: nil)
            popup.removeFromSuperview()
        case 24,25 :
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "TakePictureHelpVC") as? TakePictureHelpViewController {
                if self.cariCnt != nil{
                    vc.cariCnt = self.cariCnt
                    vc.point = self.point
                }
                self.present(vc, animated: true, completion: nil)
            }
            popup.removeFromSuperview()
        default:
            popup.removeFromSuperview()
            break
        }
    }
    
        //음성 녹음 관련 메소드**
    
    //녹음시작
    func recordStart(reRec : Bool){
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var recordingName = ""
        if  !reRec {
            firstRecord = true
            recordingName = "record.wav"
        }else{
            recordingName = "record_modulation.wav"
        }
        fileUrl = documentDirectory.appendingPathComponent(recordingName)
        let recordSettings = [
            AVFormatIDKey:Int(kAudioFormatLinearPCM),
            AVSampleRateKey:22050.0,
            AVNumberOfChannelsKey:1,
//            AVLinearPCMBitDepthKey:8,
            AVLinearPCMBitDepthKey:16,
            AVLinearPCMIsFloatKey:false,
            AVLinearPCMIsBigEndianKey:false,
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue
            ] as [String : Any]
        print(fileUrl)
        print("isRecording : \(audioRecorder?.isRecording)" )
        do {
            // selectAudioFile 함수에서 저장한 audioFile을 url로 하는 audioRecorder 인스턴스를 생성
            if audioRecorder == nil {
                if !reRec{
                    audioBaseRecorder = try AVAudioRecorder(url: fileUrl!, settings: recordSettings)
                }
                audioRecorder = try AVAudioRecorder(url: fileUrl!, settings: recordSettings)
                audioRecorder?.delegate = self
                audioRecorder?.prepareToRecord()
                audioRecorder?.record()
                print("wav save")
            }else{
                if audioRecorder?.isRecording == false {
                    if !reRec{
                        audioBaseRecorder = try AVAudioRecorder(url: fileUrl!, settings: recordSettings)
                    }
                    audioRecorder = try AVAudioRecorder(url: fileUrl!, settings: recordSettings)
                    audioRecorder?.delegate = self
                    audioRecorder?.prepareToRecord()
                    audioRecorder?.record()
                    print("wav save")
                }else{
                    stopRecorder(isTimeMax: false)
                    stopPlay()
                    print("audioRecorder........")
                }
            }
            
        } catch let error as NSError {
            print("error-initRecord:\(error)")
        }
    }
    //녹음 중지
    func stopRecorder(isTimeMax : Bool){
        if audioRecorder?.isRecording == true  && !isReRecordState{
            audioRecorder?.stop()
            do{
                print("stopRecorder !!")
                webView.evaluateJavaScript("javascript:recState = false;", completionHandler: nil)
                audioFile = try AVAudioFile(forReading: (audioRecorder?.url)!)
                if isTimeMax {
                    if isVoiceModule == "1"{
                        if audioRecorder?.isRecording == false{
                            do{
                                playAudioAtRateAndPitch(modulation: true)
                            }catch{}
                        }
                    }else if isVoiceModule == "0"{
                        if audioRecorder?.isRecording == false{
                            do{
                                playAudioAtRateAndPitch(modulation: false)
                            }catch{}
                        }
                    }
                }
            }catch{
            }
        }
    }
    //플레이 중지
    func stopPlay(){
        if audioPlayerNode != nil {
            if audioPlayerNode.isPlaying {
                audioPlayer?.currentTime = 0
                audioPlayerNode.stop()
            }
        }
    }
    //녹음 및 플레이 재생
    func playAudioAtRateAndPitch(modulation : Bool) {
        audioEngine = AVAudioEngine()
        audioRatePitch = AVAudioUnitTimePitch()
        audioPlayerNode = AVAudioPlayerNode()
        audioPlayerNode.stop()
        
        isPlayState = true
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
        do {
            if modulation{
                audioFile = try AVAudioFile(forReading: (audioRecorder?.url)!)
                try audioFile.read(into: buffer!)
            }else{
                audioFile = try AVAudioFile(forReading: (audioBaseRecorder?.url)!)
                try audioFile.read(into: buffer!)
            }
        } catch _ {
            
        }
        audioEngine.attach(audioPlayerNode)
        if modulation {
            if firstRecord{
                print("firstRecord true")
                audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: 33075.0, channels: 1))
            }else{
                print("firstRecord false")
                audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: 22050.0, channels: 1))
            }
            
        }else{
            audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: 22050.0, channels: 1))
        }
        self.audioPlayerNode.scheduleBuffer(buffer!, completionHandler: {
            print("Complete")
            self.isRecorded = true
            if modulation && self.firstRecord{
                print("audio Stop")
                self.audioRecorder?.stop()
                self.isReRecordState = false
                self.firstRecord = false
            }
            
        })
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch _ {
            print("Play session Error")
        }
        audioPlayerNode.play()
        print("modulation : \(modulation) , firstRecord : \(firstRecord)")
        if modulation && firstRecord{
            print("recordStart !!")
            isReRecordState = true
            recordStart(reRec: true)
        }
    }
    
    //인앱결제 상품정보 요청 함수
    func getProductInfo(){
        if SKPaymentQueue.canMakePayments(){
            //애들에 상품 정보를 요청, 요청이 완료되면 productsRequest함수가 자동 호출됨
            let request = SKProductsRequest(productIdentifiers: NSSet(object: self.productID) as! Set<String>)
            request.delegate = self
            request.start()
            print("상품정보 요청")
        }else{
            let message :NSDictionary = [
                "title" : "알림",
                "contents" : "설정에서 인앱결제를 활성화 해주세요.",
                "type" : 0,
                "popupType" : 0
            ]
            showDialog(message: message)
        }
    }
    
    var inappPoint = 0
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        var products = response.products
        //상품정보가 정상적으로 수신되었을 경우
        if products.count != 0 {
            product = products[0] as SKProduct
//            print(product!.localizedTitle)
//            print(product!.localizedDescription)
            var pointString = (product!.localizedTitle).split(separator: " ")
            inappPoint = Int(pointString[0])!
            buyProduct(product!)
        }else{
            print("애플 계정에 등록된 상품정보 확인 불가")
        }
        
        let productList = response.invalidProductIdentifiers
        for productItem in productList {
            print("product not found :\(productItem)")
        }
    }
    
    func requestBuyPoint(){
        let url = "\(HTTPUtil.IP)/app/point/buyPoint"
        let ud = UserDefaults.standard
        ud.string(forKey: "id")
        let param : Parameters = [
            "point" : inappPoint,
            "id" : ud.string(forKey: "id")!,
            "type" : 1
        ]
        print("param : \(param)")
        Alamofire.request(url, method: .post, parameters: param).responseJSON{
            (response) in
            if let JSON = response.result.value as? [String:Any] {
                let result : Bool = JSON["result"] as! Bool
                if result {
                    let message :NSDictionary = [
                        "title" : "알림",
                        "contents" : "포인트가 충전되었습니다.",
                        "type" : 1,
                        "popupType" : 0
                    ]
                    self.showDialog(message: message)
                }else{
                    let message :NSDictionary = [
                        "title" : "알림",
                        "contents" : "포인트 충전중 오류가 발생했습니다.",
                        "type" : 0,
                        "popupType" : 0
                    ]
                    self.showDialog(message: message)
                }
            }else{
                let message :NSDictionary = [
                    "title" : "알림",
                    "contents" : "포인트 충전중 오류가 발생했습니다.",
                    "type" : 0,
                    "popupType" : 0
                ]
                self.showDialog(message: message)
            }
        }
    }
    
    func buyProduct(_ product: SKProduct){
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions as [SKPaymentTransaction]{
            print("aaaa")
            switch transaction.transactionState {
            case .purchasing:
                print("purchasing")
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                print("실패")
            case .restored:
                print("restored")
            case .deferred:
                print("deferred")
            case .purchased:
                print("구매 정상완료될 경우 후처리 시작")
                SKPaymentQueue.default().finishTransaction(transaction)
                requestBuyPoint()
            }
        }
    }

    //인앱결제
    func inAppBilling(message : NSDictionary){
        guard let id = message.value(forKey: "id") as? String else{
            return
        }
        guard let point = message.value(forKey: "point") as? String else{
            return
        }
        
        switch point {
        case "3000":
            productID = "iap_item01"
        case "5000":
            productID = "iap_item02"
        case "10000":
            productID = "iap_item03"
        case "15000":
            productID = "iap_item04"
        case "50000":
            productID = "iap_item05"
        case "100000":
            productID = "iap_item06"
        default:
            return
        }
        
        getProductInfo();
        
        
    }

    
}


extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false){
            () in
            print("action cencel")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: false){
            () in
            guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else{
                return
            }
            self.fileName = ShardUtil.makeFile()
            
            guard let imageData = UIImageJPEGRepresentation(image, 0.8)  else{
                print("not JPEG represention of UIIage")
                return
            }
            self.imageData = imageData
            
            let strBase64 = imageData.base64EncodedString(options: .endLineWithCarriageReturn)
            self.webView.evaluateJavaScript("javascript:$('#profile-image').attr('src','data:image/jpg;base64,\(strBase64)');", completionHandler: nil)
            self.webView.evaluateJavaScript("javascript:$('#profile_image_str').val('\(self.fileName)');", completionHandler: nil)
        }
    }
}


extension MainViewController: WKScriptMessageHandler, WKNavigationDelegate {
    
    //웹페이지 시작할때 로딩화면 추가
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        activityIndicator.color = UIColor.orange
        activityIndicator.frame = CGRect(x: view.frame.midX-25, y: view.frame.midY-25, width: 50, height: 50)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    //웹페이지 종료시 로딩화면 삭제
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //webView.evaluateJavaScript("javascript:alert('\(String(describing: webView.url?.absoluteString))');", completionHandler: nil)
        activityIndicator.removeFromSuperview()
        activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        //웹페이지 롱클릭시 터치 이벤트 해제(범위설정 및 복사 붙여널기 등 이벤트)
        webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'", completionHandler: nil)
        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'", completionHandler: nil)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.removeFromSuperview()
        activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.removeFromSuperview()
        activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    //wkwebView 기본 설정 (기본 alert 위해)
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let properString = message.removingPercentEncoding
        let alertController = UIAlertController(title: "", message: properString, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let properString = message.removingPercentEncoding
        let alertController = UIAlertController(title: "", message: properString, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let properString = prompt.removingPercentEncoding
        let alertController = UIAlertController(title: "", message: properString, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            return nil
        }
        
        guard let targetFrame = navigationAction.targetFrame, targetFrame.isMainFrame else {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
                // Fallback on earlier versions
            }
            return nil
        }
        return nil
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        switch message.name {
        case "setFloattingBtn":
            print("setFloattingBtn")
        case "showDialog" :
            if let message = message.body as? NSDictionary {
                //print(message)
                showDialog(message: message)
            }
        case "setAutoLogin" :
            if let message = message.body as? NSDictionary {
                print(message)
                ShardUtil.setLoginInfo(member: message)
            }
        case "setProfileImage":
            if let type = message.body as? String {
                if type == "1" {
                    uploadFromAlbum()
                }else {
                    uploadFromCamera()
                }
            }
        case "sendProfile" :
            if let message = message.body as? NSDictionary {
                self.profileUpdate(message: message);
            }
        case "versionCheck":
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                webView.evaluateJavaScript("javascript:versionCheck('\(version)')", completionHandler: nil)
            }
        case "faceDataInit" :
            let ud = UserDefaults.standard
            ud.set("/resources/img/cms/face_sample.png", forKey: "face_url")
            webView.evaluateJavaScript("javascript:location.reload();", completionHandler: nil)
        case "setFaceImage" :
            if let data = message.body as? String {
                let ud = UserDefaults.standard
                ud.set(data, forKey: "face_url")
            }
        case "getFaceImage" :
            let ud = UserDefaults.standard
            let face_url = ud.string(forKey: "face_url") ?? ""
            webView.evaluateJavaScript("javascript:getFaceImage('\(face_url)');", completionHandler: nil)
        case "setPrevPage" :
            if let idx = message.body as? Int {
                prevPage = idx
            }
        case "getHairImage" :
            let ud = UserDefaults.standard
            let hair_url = ud.string(forKey: "hair_url") ?? ""
            let hair_x = ud.string(forKey: "hair_x") ?? ""
            let hair_y = ud.string(forKey: "hair_y") ?? ""
//            print("hair_url : \(hair_url) \n hair_x : \(hair_x) \n hair_y : \(hair_y)")
//            print("javascript:getHairImage('\(hair_url)',\(hair_x!),\(hair_y!));")
            webView.evaluateJavaScript("javascript:getHairImage('\(hair_url)',\(hair_x),\(hair_y));", completionHandler: nil)
        case "setHairImage":
            if let message = message.body as? NSDictionary {
                let ud = UserDefaults.standard
//                print("Hair_x : \(message.value(forKey: "hair_x")!) , Hair_y : \(message.value(forKey: "hair_y")!)")
                ud.set(message.value(forKey: "hair_src"), forKey: "hair_url")
                ud.set(message.value(forKey: "hair_x")!, forKey: "hair_x")
                ud.set(message.value(forKey: "hair_y")!, forKey: "hair_y")
            }
        case "getPrevPage" :
            webView.evaluateJavaScript("javascript:getPrevPage(\(prevPage));", completionHandler: nil)
            break
        case "downloadEmoticon" :
            if let record = message.body as? Bool {
                print("record : \(record)")
                if record {
                    recordFileUpload(record: true)
                }else{
                    recordFileUpload(record: false)
                }
            }
        case "shareImage" :
            if let message = message.body as? NSDictionary {
                let util = ShardUtil()
                util.shareEmoticon(message: message, vc: self)
            }
        case "retakeCamera" :
            if let message = message.body as? NSDictionary {
                self.retakeCamera = (message.value(forKey: "isRetake") != nil)
                self.fail_reg_no = message.value(forKey: "reg_no") as! String
//                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "CustomCamera") as? CustomCameraController {
//                    vc.retake = self.retakeCamera
//                    vc.fail_reg_no = self.fail_reg_no
//                    self.present(vc, animated: true, completion: nil)
//                }
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "TakePictureHelpVC") as? TakePictureHelpViewController {
                    vc.retake = self.retakeCamera
                    vc.fail_reg_no = self.fail_reg_no
                    self.present(vc, animated: true, completion: nil)
                }
            }
        case "makeEmoticon" :
            if let record = message.body as? Bool {
                print("message Bool : \(record)")
                self.record = record
                if record {
                    if isRecorded {
                        let message :NSDictionary = [
                            "title" : "저장",
                            "contents" : "포인트를 사용하여 이모티콘을 저장하시겠습니까?",
                            "type" : 21,
                            "popupType" : 1
                        ]
                        showDialog(message: message)
                    }else{
                        let message :NSDictionary = [
                            "title" : "알림",
                            "contents" : "음성 녹음을 먼저 실행해주시기 바랍니다.",
                            "type" : 0,
                            "popupType" : 0
                        ]
                        showDialog(message: message)
                    }
                }else{
                    let message :NSDictionary = [
                        "title" : "저장",
                        "contents" : "포인트를 사용하여 이모티콘을 저장하시겠습니까?",
                        "type" : 21,
                        "popupType" : 1
                    ]
                    showDialog(message: message)
                }
            }
        case "makeRecBtn" :
            if let module = message.body as? String {
                //print("module: \(module)")
                isVoiceModule = module
                if audioRecorder != nil {
                    //print("isRecording : \(audioRecorder?.isRecording)")
                    if (audioRecorder?.isRecording)! == true {
                        isCancel = true
                        audioRecorder?.stop()
                        do{
                            audioFile = try AVAudioFile(forReading: (audioRecorder?.url)!)
                            if module == "1"{
                                if audioRecorder?.isRecording == false{
                                    do{
                                        playAudioAtRateAndPitch(modulation: true)
                                        reloadCheck = false
                                    }catch{}
                                }
                            }else if module == "0"{
                                if audioRecorder?.isRecording == false{
                                    do{
                                        playAudioAtRateAndPitch(modulation: false)
                                        reloadCheck = false
                                    }catch{}
                                }
                            }
                        }catch{
                        }
                        
                    }else if audioPlayerNode != nil && audioPlayerNode.isPlaying && !isPlayState{
                        audioPlayer?.currentTime = 0
                        audioPlayerNode.stop()
                    }else{
                        isPlayState = false
                        recordStart(reRec: false)
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                            if !self.isCancel {
                                self.webView.evaluateJavaScript("javascript:$('.play_btn').trigger('click');", completionHandler: nil)
                                self.stopRecorder(isTimeMax: true)
                            }else{
                                print("not recorder stop")
                                self.isCancel = false
                            }
                        }
                    }
                }else{
                    recordStart(reRec: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                        if !self.isCancel {
                            print("stopRecorder **")
                            self.webView.evaluateJavaScript("javascript:$('.play_btn').trigger('click');", completionHandler: nil)
                            self.stopRecorder(isTimeMax: true)
                        }else{
                            print("not recorder stop")
                            self.isCancel = false
                        }
                        
                    }
                }
            }
        case "voiceModuleBtn":
            if let module = message.body as? String {
                isVoiceModule = module
                print(isVoiceModule)
                if isVoiceModule == "1"{
                    if audioRecorder?.isRecording == false{
                        do{
                            playAudioAtRateAndPitch(modulation: true)
                        }catch{}
                    }else{
                        if reloadCheck {
                            webView.evaluateJavaScript("javascript:$('#microphone_btn').trigger('click');", completionHandler: nil)
                        }
                        
                    }
                }else if isVoiceModule == "0"{
                    if audioRecorder?.isRecording == false{
                        do{
                            playAudioAtRateAndPitch(modulation: false)
                        }catch{}
                    }else{
                        if reloadCheck {
                            webView.evaluateJavaScript("javascript:$('#microphone_btn').trigger('click');", completionHandler: nil)
                        }
                    }
                }
            }
        case "removeRecorder" :
            //이모티콘 페이지에서 뒤로가기시 음성 레코드 초기화
            if audioRecorder != nil {
                audioRecorder = nil
            }
        case "cariCntPointCheck" :
            if let message = message.body as? NSDictionary {
                cariCnt = (message.value(forKey: "cari_cnt") as! NSString).integerValue
                point = (message.value(forKey: "point") as! NSString).integerValue
                //point = message.value(forKey: "point") as! Int
                
            }
        
        case "recReload" :
            reloadCheck = true
            if audioRecorder != nil {
                audioRecorder = nil
            }
        case "myPhoneNumber" : break
        case "sendPushKey":
            if let message = message.body as? NSDictionary {
                let id = message.value(forKey: "id") as! String
                let ud = UserDefaults.standard
                guard let pushKey = ud.string(forKey: "push_key") else{
                    return
                }
                if id != ""{
                    let push_key = pushKey
                    let url = "\(HTTPUtil.IP)/app/push/send_push_key"
                    let param : Parameters = [
                        "member_id" : id,
                        "device" : "ios",
                        "push_key" : push_key
                    ]
                    Alamofire.request(url, method: .post, parameters: param).responseJSON{
                        (response) in
                        if let JSON = response.result.value as? [String:Any] {
                            print(JSON)
                        }
                    }
                }
                
            }
        case "inAppBilling" :
            if let message = message.body as? NSDictionary {
                inAppBilling(message: message)
            }
        case "showFirstPopup" :
            if self.isStart {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let today = formatter.string(from: Date())
                let ud = UserDefaults.standard
                let except_reg_no = ud.string(forKey: today) ?? ""
                self.isStart = false
                webView.evaluateJavaScript("javascript:getMainAd('\(except_reg_no)');", completionHandler: nil)
            }
        case "setMainAdToday":
            if let message = message.body as? NSDictionary {
                let reg_no = message.value(forKey: "reg_no") as! String
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let today = formatter.string(from: Date())
                let ud = UserDefaults.standard
                var except_reg_no = ud.string(forKey: today) ?? ""
                if except_reg_no == "" {
                    except_reg_no = reg_no
                }else{
                    except_reg_no += ",\(reg_no)"
                }
                print(except_reg_no)
                ud.setValue(except_reg_no, forKey: today)
            }
        default:
            break
        }
    }
}

//핵사 코드 컬러
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}



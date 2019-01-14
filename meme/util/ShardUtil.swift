import Foundation
import UIKit
import WebKit
import Alamofire
import Kingfisher
import AssetsLibrary
import Photos

class ShardUtil :  UIViewController,UIDocumentInteractionControllerDelegate{
    //UIActivityViewController
    var vc = UIViewController()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func ShardUtil(vc: UIViewController) {
        self.vc = vc
        
    }
//    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
//        //사진 저장 한후
//        if let error = error {
//            // we got back an error!
//            print("파일저장에 문제가 발생했습니다.")
//            self.showToast(message: "파일저장에 문제가 발생했습니다.")
//
//        } else {
//            print("앨범에 저장되었습니다.")
//            self.showToast(message: "앨범에 저장되었습니다.")
//        }
//    }
    
    //로그인 정보 저장
    static func setLoginInfo(member : NSDictionary){
        let ud = UserDefaults.standard
        ud.set(member["id"] ?? "", forKey: "id")
        ud.set(member["passwd"] ?? "", forKey: "passwd")
        guard let pushKey = ud.string(forKey: "push_key") else{
            return
        }
        guard let id = member["id"] as? String else{
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
   
    //로그인 정보 삭제
    static func setLogout(){
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "id")
        ud.removeObject(forKey: "passwd")
    }
    
    //파일이름 생성 (확장자명 필요없이 생성할때 사용)
    static func makeFile() -> String{
        let result : String
        let num = Int(NSDate().timeIntervalSince1970 * 1000)
        result = "IMG_\(String(num)).jpg"
        
        return result
    }
    
    func shareEmoticon(message: NSDictionary, vc : UIViewController){
        self.vc = vc
        var shareType = ""
        if let filePath = message.value(forKey: "filePath") as? String {
            let fileUrl = "\(HTTPUtil.IP)\(filePath)"
            let url = URL(string: fileUrl)!
//            let data = NSData(contentsOf: URL(string: fileUrl)!)
//            let localUrl = Bundle.main.url(forResource: "test_gif", withExtension: "gif")
//            print("data : \(url)    local : \(localUrl)")

            print("fileUrl :"+fileUrl);
            print("filePath :"+filePath)
            let index = filePath.index(filePath.endIndex, offsetBy: -3)
            let fileType = filePath.substring(from: index)
            if fileType == "mp4"{
                DispatchQueue.global(qos: .background).async {
                    if let urlData = NSData(contentsOf: url){
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let filePath="\(documentsPath)/tempFile.mp4"
                        DispatchQueue.main.async {
                            urlData.write(toFile: filePath, atomically: true)
                            
                            if let packageName = message.value(forKey: "packageName") as? String{
                                if packageName == "download" {
                                    PHPhotoLibrary.shared().performChanges({
                                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                                    }, completionHandler: { (completed, error) in
                                        if completed {
                                            DispatchQueue.main.async {
                                                self.showToast(message: "앨범에 다운로드가 완료되었습니다.")
                                            }
                                        }
                                    })
                                    return
                                }else if packageName == "com.twitter.android"{
                                    DispatchQueue.main.async {
                                        self.showToast(message: "지원하지 않는 형식입니다.")
                                    }
                                    return
                                }
                            }
                            //Hide activity indicator
                            let activityVC = UIActivityViewController(activityItems: [NSURL(fileURLWithPath: filePath)], applicationActivities: nil)
                            activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact]
                            vc.present(activityVC, animated: true, completion: nil)
                        }
                    }
                }
            }else if fileType == "gif"{
                ImageDownloader.default.downloadImage(with: url, options: [], progressBlock: nil) {
                    (image, error, url, data) in
                    let file = "file.gif"
                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = dir.appendingPathComponent(file)
                        //writing
                        do {
                            try data?.write(to: fileURL)
                        }
                        catch {/* error handling here */}
                        if let packageName = message.value(forKey: "packageName") as? String{
                            if packageName == "download" {
                                PHPhotoLibrary.shared().performChanges({
                                    _ = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                                }, completionHandler: { (success, error) in
                                    if success {
                                        print("ok")
                                        DispatchQueue.main.async {
                                            self.showToast(message: "앨범에 다운로드가 완료되었습니다.")
                                        }
                                    }
                                    else {
                                        print(error?.localizedDescription)
                                        self.showToast(message: "앨범에 다운로드 중 문제가 발생했습니다.")
                                    }
                                })
                                return
                            }
                        }
                        let fileToShare = [fileURL]
                        //let fileToShare = [data]
                        let activityVC = UIActivityViewController(activityItems: fileToShare, applicationActivities: nil)
                        vc.present(activityVC, animated: true, completion: nil)
                    }
                }
            }
        }
        return
    }
    
    //토스트 메시지
    func showToast(message : String) {
        let toastLabel = UILabel(frame: CGRect(x: vc.view.frame.size.width/2 - 150, y: vc.view.frame.size.height - 100, width:300, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.lineBreakMode = .byCharWrapping
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.numberOfLines = 4
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        vc.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
}

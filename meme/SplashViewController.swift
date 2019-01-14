
import UIKit
import WebKit

import Alamofire


class SplashViewController : UIViewController {
    
    @IBOutlet weak var splashImage: UIImageView!
    //세로고정
    private var _orientations = UIInterfaceOrientationMask.portrait
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get { return self._orientations }
        set { self._orientations = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let animationImages:[AnyObject] = [UIImage(named: "splashgif01")!, UIImage(named: "splashgif02")!, UIImage(named: "splashgif03")!, UIImage(named: "splashgif04")!,UIImage(named: "splashgif05")!]
        
        self.splashImage.animationImages = animationImages as? [UIImage]
        self.splashImage.animationDuration = 1
        self.splashImage.animationRepeatCount = 1
        self.splashImage.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        let ud = UserDefaults.standard
        if let id = ud.string(forKey: "id"),let passwd = ud.string(forKey: "passwd"){
            let url = "\(HTTPUtil.IP)/app/appmember/member_login"
            
            print("id : \(id), passwd:\(passwd)")
            let param : Parameters = [
                "id" : id,
                "passwd" : passwd
            ]
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                Alamofire.request(url, method: .post, parameters: param).responseJSON{
                    response in
                    if let JSON = response.result.value as? [String:Any]{
                        if let result : Bool = JSON["result"] as? Bool {
                            if result {
                                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRvCtrl") as? SWRevealViewController {
                                    
                                    MemeExternData.sharedInstance.isAutoLogin = true
                                    MemeExternData.sharedInstance.id = id
                                    MemeExternData.sharedInstance.passwd = passwd
                                    //vc.isAutoLogin = true
                                    //vc.id = id
                                   // vc.passwd = passwd
                                    self.present(vc, animated: true, completion: nil)
                                }
                            }
                            else{
                                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRvCtrl") as? SWRevealViewController {
                                    MemeExternData.sharedInstance.isAutoLogin = false
                                    //vc.isAutoLogin = false
                                    self.present(vc, animated: true, completion: nil)
                                }
                                print("error")
                            }
                        }
                    }
                }
            })
        }else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRvCtrl") as? SWRevealViewController {
                    MemeExternData.sharedInstance.isAutoLogin = false
                    //vc.isAutoLogin = false
                    self.present(vc, animated: true, completion: nil)
                }
            })
            
        }
    }
}

//
//  SideMenuControllerswift.swift
//  meme
//
//  Created by 밈개발자 on 08/01/2019.
//  Copyright © 2019 exs. All rights reserved.
//

import Foundation

import WebKit
import Alamofire
import AVFoundation
import StoreKit


class SideMenuController: UITableViewController{
    
   @IBOutlet weak var profileContainer: UIView!
    
    
//    //로그인 안했을때 outlet variable
//    @IBOutlet weak var nav_comment_logout: UILabel!
//    @IBOutlet weak var nav_profileimg_logout: UIImageView!
//    @IBOutlet weak var nav_memberBtn_logout: UIButton!
//    @IBOutlet weak var nav_login_logout: UIButton!
//
//    @IBOutlet weak var nav_banner_container: UIView!
//
    
    //초기화코드
//    override func viewDidLoad() {
//        super.viewDidLoad()
       // let rect = CGRect(x: 16, y: 16, width: 100, height: 100)
        
    //    nav_comment_logout.backgroundColor = UIColor.red
     //   nav_comment_logout.translatesAutoresizingMaskIntoConstraints = false
//        redView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        redView.topAnchor.constraint(equalTo: profileContainer.bottomAnchor).isActive = true
//        redView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        redView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.bottomAnchor).isActive = true
 //       profileContainer.addSubview(nav_comment_logout)
        
        
//    }
    
//    func nav_logout(){
//        
//    }
//    func nav_login(){
//        
//    }
//    
    //테이블뷰셀의 숫자를 설정한다.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    //행의높이를 지정한다.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0
        {
            MemeExternData.sharedInstance.stringusrl = "\(HTTPUtil.IP)/app/myemoticon?type=-1"
        }
        if indexPath.row == 1
        {
            MemeExternData.sharedInstance.stringusrl = "\(HTTPUtil.IP)/app/notices/list"
        }
        if indexPath.row == 2
        {
            MemeExternData.sharedInstance.stringusrl = "\(HTTPUtil.IP)/app/order/list"
        }

        if indexPath.row == 3
        {
            UIApplication.shared.open(URL(string: "https://m.facebook.com/emoticon.meme")!, options: [:], completionHandler: nil)
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRvCtrl") as? SWRevealViewController {

                self.present(vc, animated: true, completion: nil)
            }
        }
        if indexPath.row == 4
        {
            //MemeExternData.sharedInstance.stringusrl = "\(HTTPUtil.IP)/app/order/list"
            UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/%EB%B0%88-meme/id1374125711?mt=8")!, options: [:], completionHandler: nil)
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRvCtrl") as? SWRevealViewController {

                self.present(vc, animated: true, completion: nil)
            }
        }
        if indexPath.row == 5
        {
            MemeExternData.sharedInstance.stringusrl = "\(HTTPUtil.IP)/app/order/list"
        }
        if indexPath.row == 6
        {
            MemeExternData.sharedInstance.stringusrl = "\(HTTPUtil.IP)/app/cs/main"
        }
        if indexPath.row == 7
        {
            MemeExternData.sharedInstance.stringusrl = "\(HTTPUtil.IP)/app/setting/main"
        }
    }
}

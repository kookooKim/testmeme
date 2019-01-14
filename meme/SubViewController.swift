//
//  SubViewController.swift
//  meme
//
//  Created by 밈개발자 on 03/01/2019.
//  Copyright © 2019 exs. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import Alamofire
import AVFoundation
import StoreKit


class SubViewController: UIViewController, WKUIDelegate{
    
    @IBOutlet weak var SubWebView: WKWebView!
    var activityIndicator = UIActivityIndicatorView()  //로딩뷰
    
    @IBAction func BackButton(_ sender: Any) {
        //dismiss(animated: true, completion: nil)
        
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SWRvCtrl") as? SWRevealViewController {
            
            self.present(vc, animated: true, completion: nil)
        }
    }
    
   override func viewDidLoad() {
       super.viewDidLoad()
    
        let subcontentController = WKUserContentController()
        let subcontrollArray : [String] = ["showDialog","setFloattingBtn","setAutoLogin","myPhoneNumber","setProfileImage","sendProfile","versionCheck","faceDataInit","setFaceImage","getFaceImage","setPrevPage","getPrevPage","shareImage","downloadEmoticon","setHairImage","getHairImage","retakeCamera","makeEmoticon","makeRecBtn","voiceModuleBtn","removeRecorder","cariCntPointCheck","recReload","sendPushKey","inAppBilling","showFirstPopup","setMainAdToday"]
        for subcontent in subcontrollArray {
            subcontentController.add(self, name: subcontent)
        }
    
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = subcontentController
        SubWebView = WKWebView(frame: self.SubWebView.frame, configuration: webConfiguration)
        SubWebView.uiDelegate = self
        SubWebView.navigationDelegate = self
        //webView.allowsBackForwardNavigationGestures = true
        SubWebView.scrollView.bounces = false
        self.view.addSubview(SubWebView)
    
        
        
        let url = URL(string: MemeExternData.sharedInstance.stringusrl)
        print("\(String(describing: url))")
        let myRequest = URLRequest(url: url!)
        self.SubWebView.load(myRequest)
   }
    
    override func viewWillAppear(_ animated: Bool) {
//        var viewBounds : CGRect = self.view.bounds
//        viewBounds.origin.y = 20
//        viewBounds.size.height = viewBounds.size.height - 20
//        self.SubWebView.frame = viewBounds
        
    }
}

extension SubViewController: WKScriptMessageHandler, WKNavigationDelegate {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    }
    
    
    //웹페이지 시작할때 로딩화면 추가
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
//        activityIndicator.color = UIColor.orange
//        activityIndicator.frame = CGRect(x: view.frame.midX-25, y: view.frame.midY-25, width: 50, height: 50)
//        activityIndicator.hidesWhenStopped = true
//        activityIndicator.startAnimating()
//        view.addSubview(activityIndicator)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    //웹페이지 종료시 로딩화면 삭제
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //webView.evaluateJavaScript("javascript:alert('\(String(describing: webView.url?.absoluteString))');", completionHandler: nil)
//        activityIndicator.removeFromSuperview()
//        activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        //웹페이지 롱클릭시 터치 이벤트 해제(범위설정 및 복사 붙여널기 등 이벤트)
        webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'", completionHandler: nil)
        webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'", completionHandler: nil)
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
            
            //webView.load(URLRequest(url: url))
            return nil
        }
        return nil
    }
}

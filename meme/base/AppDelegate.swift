//
//  AppDelegate.swift
//  meme
//
//  Created by 이매지니어스 on 2017. 12. 7..
//  Copyright © 2017년 exs. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import Google
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GGLInstanceIDDelegate, GCMReceiverDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let ud = UserDefaults.standard

    var connectedToGCM = false
    var subscribedToTopic = false
    var gcmSenderID: String?
    var registrationToken: String?
    var registrationOptions = [String: AnyObject]()
    
    let registrationKey = "onRegistrationCompleted"
    let messageKey = "onMessageReceived"
    let subscriptionTopic = "/topics/global"
    
    private let categoryId = "myNotificationCategory"
    
    
    //ReceiveRemoteNotification when app's state is foreground state.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("userInfo: \(userInfo)")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //firebase 설정
        FirebaseApp.configure()
        
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        //assert(configureError == nil, "Error configuring Google services: \(String(describing: configureError))")
        gcmSenderID = GGLContext.sharedInstance().configuration.gcmSenderID
        
        if #available(iOS 10.0, *){
            print("ios 10.0")
            //UNUserNotificationCenter.current().requestAuthorization(options:[.alert, .sound]){ (granted, error) in }
            //application.registerForRemoteNotifications()
            
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization.
            }
            application.registerForRemoteNotifications()
            center.delegate = self
        }else if #available(iOS 9.0, *){
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        else if #available(iOS 8.0, *) {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            // Fallback
            //UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert], categories: nil))
            //UIApplication.shared.registerForRemoteNotifications()
            let types: UIRemoteNotificationType = [.alert, .sound]
            application.registerForRemoteNotifications(matching: types)
        }
        
        let gcmConfig = GCMConfig.default()
        gcmConfig?.receiverDelegate = self
        GCMService.sharedInstance().start(with: gcmConfig)
        
        return true
    }
    
  
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
        //print("ios 10.0 content: \(notification.request.content)")
        print("ios 10.0 : \(notification.request.content.userInfo)")
        print("callback 1")
        //        let userInfo = notification.request.content.userInfo
        //        if notification.request.content.userInfo["push_type"]! as! String == "2" {
        //            reinstateBackgroundTask()
        //            startVibration()
        //        }
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
        print("callback 2")
    }
    
    func subscribeToTopic() {
        // If the app has a registration token and is connected to GCM, proceed to subscribe to the
        // topic
        if registrationToken != nil && connectedToGCM {
            GCMPubSub.sharedInstance().subscribe(withToken: self.registrationToken, topic: subscriptionTopic,
                                                 options: nil, handler: { error -> Void in
                                                    if let error = error as NSError? {
                                                        // Treat the "already subscribed" error more gently
                                                        if error.code == 3001 {
                                                            print("Already subscribed to \(self.subscriptionTopic)")
                                                        } else {
                                                            print("Subscription failed: \(error.localizedDescription)")
                                                        }
                                                    } else {
                                                        self.subscribedToTopic = true
                                                        NSLog("Subscribed to \(self.subscriptionTopic)")
                                                    }
            })
        }
    }
    
    // [START connect_gcm_service]
    func applicationDidBecomeActive( _ application: UIApplication) {
        application.applicationIconBadgeNumber = 0;
        // Connect to the GCM server to receive non-APNS notifications
        GCMService.sharedInstance().connect(handler: { error -> Void in
            if let error = error as? NSError {
                print("Could not connect to GCM: \(error.localizedDescription)")
            } else {
                self.connectedToGCM = true
                print("Connected to GCM")
                // [START_EXCLUDE]
                self.subscribeToTopic()
                // [END_EXCLUDE]
            }
        })
    }
    // [END connect_gcm_service]
    // [START disconnect_gcm_service]
    func applicationDidEnterBackground(_ application: UIApplication) {
        GCMService.sharedInstance().disconnect()
        // [START_EXCLUDE]
        self.connectedToGCM = false
        // [END_EXCLUDE]
    }
    // [END disconnect_gcm_service]
    // [START receive_apns_token]
    func application( _ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken
        deviceToken: Data ) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        // Print it to console
        print("APNs device token: \(deviceTokenString)")
        
        let instanceIDConfig = GGLInstanceIDConfig.default()
        instanceIDConfig?.delegate = self
        // Start the GGLInstanceID shared instance with that config and request a registration
        // token to enable reception of notifications
        GGLInstanceID.sharedInstance().start(with: instanceIDConfig)
        registrationOptions = [kGGLInstanceIDRegisterAPNSOption:deviceToken as AnyObject,
                               kGGLInstanceIDAPNSServerTypeSandboxOption:false as AnyObject]
        GGLInstanceID.sharedInstance().token(withAuthorizedEntity: gcmSenderID,
                                             scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
        
    }
    
    // [START receive_apns_token_error]
    func application( _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError
        error: Error ) {
        print("APNs registration failed: \(error)")
        let userInfo = ["error": error.localizedDescription]
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: registrationKey), object: nil, userInfo: userInfo)
    }
    
    func registrationHandler(_ registrationToken: String?, error: Error?) {
        if let registrationToken = registrationToken {
            self.registrationToken = registrationToken
            print("Registration Token: \(registrationToken)")
            let id = ud.string(forKey: "id") ?? ""
            if id != ""{
                let push_key = registrationToken
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
            ud.set(registrationToken, forKey: "push_key")
            
            self.subscribeToTopic()
            let userInfo = ["registrationToken": registrationToken]
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: self.registrationKey), object: nil, userInfo: userInfo)
        } else if let error = error {
            print("Registration to GCM failed with error: \(error.localizedDescription)")
            let userInfo = ["error": error.localizedDescription]
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: self.registrationKey), object: nil, userInfo: userInfo)
        }
    }
    
    // [START on_token_refresh]
    func onTokenRefresh() {
        // A rotation of the registration tokens is happening, so the app needs to request a new token.
        print("The GCM registration token needs to be changed.")
        GGLInstanceID.sharedInstance().token(withAuthorizedEntity: gcmSenderID,
                                             scope: kGGLInstanceIDScopeGCM, options: registrationOptions, handler: registrationHandler)
    }
    // [END on_token_refresh]
    // [START upstream_callbacks]
    func willSendDataMessage(withID messageID: String!, error: Error!) {
        if error != nil {
            // Failed to send the message.
        } else {
            // Will send message, you can save the messageID to track the message
        }
    }
    
    func didSendDataMessage(withID messageID: String!) {
        // Did successfully send message identified by messageID
    }
    // [END upstream_callbacks]
    func didDeleteMessagesOnServer() {
        // Some messages sent to this device were deleted on the GCM server before reception, likely
        // because the TTL expired. The client should notify the app server of this, so that the app
        // server can resend those messages.
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}


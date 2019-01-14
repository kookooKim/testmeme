//
//  MemeExternData.swift
//  meme
//
//  Created by 밈개발자 on 08/01/2019.
//  Copyright © 2019 exs. All rights reserved.
//

import Foundation

class MemeExternData
{
    
    //사이드 메뉴 URL
    var stringusrl = ""
    
    var isAutoLogin = false
    var id = ""
    var passwd = ""
    
    //싱글톤 만들기
    class var sharedInstance: MemeExternData {
        struct Static{
            static let instance: MemeExternData = MemeExternData()
            
        }
        return Static.instance
    }
    
    
        
        
}

//
//  DeviceInfo.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/7.
//

import Foundation

public struct DeviceInfo: Codable, CustomStringConvertible {
    public var description: String {
        return "设备信息：\n名称:\(name)\n平台:\(platform)\n地址:\(ip)\n版本:\(sdkVersion)"
    }
    
    let name: String
    let platform: String
    var ip: String
    var sdkVersion: String
        
    public init(name: String = "DeviceName",
         platform: String = "Unknown",
         ip: String = "127.0.0.1",
         sdkVersion: String  = "Unknown") {
        
        self.name = name
        self.platform = platform
        self.ip = ip
        self.sdkVersion = sdkVersion
    }

}

//
//  DeviceInfo.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/7.
//

import Foundation

public struct DeviceInfo: Codable {
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

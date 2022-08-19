//
//  File.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/17.
//

import Foundation

public struct DiscoveryInfo: Codable {
    let device: DeviceInfo
    let TcpPort: UInt16
    let UdpPort: UInt16
    
    public init(device: DeviceInfo, TcpPort: UInt16, UdpPort: UInt16) {
        self.device = device
        self.TcpPort = TcpPort
        self.UdpPort = UdpPort
    }
}

//
//  TcpListenerProtocol.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/7.
//

import Foundation

public protocol Listener {

    func deliver(data: Data)
    func notified(with message: String)
    func deliver(devices: [DeviceInfo])
}

enum YMLResponse{
    case data(data: Data)
    case message(message: String)
}

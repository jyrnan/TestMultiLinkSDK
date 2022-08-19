//
//  MockUdpServer.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/15.
//

import Foundation
import CocoaAsyncSocket

class MockUdpServer: NSObject, GCDAsyncUdpSocketDelegate{
    
    typealias Callback = Optional<() -> Void>
    var udpSocket: GCDAsyncUdpSocket?
    
    var didSendGeneralCommand: Callback = nil
    
    func setupServer() -> Bool {
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
           
            try udpSocket?.bind(toPort: 8000)
            try udpSocket?.enableBroadcast(true)
            try udpSocket?.beginReceiving()
            
            print("udp信道开始了")
            
            return true
        } catch {
            // 出错了，关闭socket
            udpSocket?.close()
            udpSocket = nil
            
            print("socket error: \(error)")
            return false
        }
    }
    
    func closeUdp() {
        udpSocket?.close()
        udpSocket = nil
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        var returnData = Data(capacity: 50)
        returnData.append(contentsOf: [0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x02, 0xff])
        returnData.append(contentsOf: "hello".data(using: .utf8)!)
        udpSocket?.send(returnData,toHost: "localhost", port: 8009, withTimeout: -1, tag: 0)
        
        didSendGeneralCommand?()
    }
}


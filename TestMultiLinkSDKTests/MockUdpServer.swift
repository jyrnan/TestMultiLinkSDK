//
//  MockUdpServer.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/15.
//

import Foundation
import CocoaAsyncSocket

class MockUdpServer: NSObject, GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate{
    
    typealias Callback = Optional<() -> Void>
    var udpSocket: GCDAsyncUdpSocket?
    var tcpServerSocket: GCDAsyncSocket?
    
    var didSendGeneralCommand: Callback = nil
    
    func setupTcpServer() -> Bool {
        tcpServerSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try tcpServerSocket?.accept(onPort: 8000)
            print("MockServer tcp信道开始了")
            
            return true
        } catch {
            print("socket error: \(error)")
            return false
        }

    }
    
    func setupUdpServer() -> Bool {
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
           
            try udpSocket?.bind(toPort: 8000)
            try udpSocket?.enableBroadcast(true)
            try udpSocket?.beginReceiving()
            
            print("MockServer udp信道开始了")
            
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
    
    //MARK: - Delegate part
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        var returnData = Data(capacity: 50)
        returnData.append(contentsOf: [0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x02, 0xff])
        returnData.append(contentsOf: "hello".data(using: .utf8)!)
        udpSocket?.send(returnData,toHost: "localhost", port: 8009, withTimeout: -1, tag: 0)
        
        didSendGeneralCommand?()
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print(sock.description)
        didSendGeneralCommand?()
    
        print(#line, #function,"\n接受TCP连接成功." + "连接地址: " + newSocket.connectedHost! + " 端口号: \(newSocket.connectedPort)")
        
        
        // 第一次开始读取Data
        newSocket.readData(withTimeout: -1, tag: 0)
    }
}


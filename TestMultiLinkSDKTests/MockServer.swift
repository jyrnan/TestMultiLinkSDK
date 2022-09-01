//
//  MockUdpServer.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/15.
//

import Foundation
import CocoaAsyncSocket

class MockServer: NSObject, GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate{
    
    typealias Callback = Optional<() -> Void>
    var udpSocket: GCDAsyncUdpSocket?
    var tcpServerSocket: GCDAsyncSocket?
    var tcpClients = [GCDAsyncSocket]()
    
    var tcpPort: UInt16
    var udpPort: UInt16
    
    var didSendGeneralCommand: Callback = nil
    var didAcceptNewSocket: Callback = nil
    var didReadTcpData: Callback = nil
    
    var shouldRecieveData: Data? = nil
    
    init(tcpPort: UInt16, udpPort: UInt16) {
        self.tcpPort = tcpPort
        self.udpPort = udpPort
    }
    
    func setupTcpServer() -> Bool {
        tcpServerSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try tcpServerSocket?.accept(onPort: tcpPort)
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
           
            try udpSocket?.bind(toPort: udpPort)
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
        didAcceptNewSocket?()
    
        print(#line, #function,"接受TCP连接成功." + "连接地址: " + newSocket.connectedHost! + " 端口号: \(newSocket.connectedPort)")
        
        self.tcpClients.append(newSocket)
        // 第一次开始读取Data
        newSocket.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print(#line, #function,"读取TCP数据成功." + "连接地址: \(sock.connectedHost)" + " 端口号: \(sock.connectedPort)")
        if data == shouldRecieveData {
            didReadTcpData?()
            sock.write(data, withTimeout: -1, tag: 0) //回复数据
        }
        
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    
}


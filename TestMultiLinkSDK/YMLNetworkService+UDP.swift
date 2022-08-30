//
//  YMLNetworkService+UDP.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/18.
//

import Foundation
import CocoaAsyncSocket

extension YMLNetworkService: GCDAsyncUdpSocketDelegate {
    // MARK: - UDPClient
    
    /// 建立UDP信道
    /// - Parameter port: 指定监听的端口号
    /// - Returns: 返回状态
    func setupUdpSocket(on port: UInt16? = nil) -> Bool {
        closeUdpSocket()
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
        
        do {
            // 如果有输入端口号才监听指定端口号;
            if let port = port {
                try udpSocket?.bind(toPort: port)
            }
            
            try udpSocket?.enableBroadcast(true)
            try udpSocket?.beginReceiving()
            
            print("udp信道开始了")
            lisener?.notified(with: "UPD监听开始了，端口号：\(udpSocket?.localPort())")
            
            return true
        } catch {
            // 出错了，关闭socket
            udpSocket?.close()
            udpSocket = nil
            
            print("socket error: \(error)")
            lisener?.notified(with: "socket error: \(error)")
            return false
        }
    }
    
    func closeUdpSocket() {
        guard let udpSocket = udpSocket else { return }
        udpSocket.close()
        self.udpSocket = nil
    }
    
    func sendUdpData(_ data: Data, to host: String, on port: UInt16) {
        if !isUdpListening {
            setupUdpSocket()
        }
        
        let encryptedData = encryptData(data: data)
        udpSocket?.send(encryptedData, toHost: host, port: port, withTimeout: -1, tag: 0)
    }
    
    /// 发送广播获取局域网内电视信息
    func searchDevice() {
        print("Start search device...")
        let sendpack: Data = makeSeachDeviceSendPack()
        
        sendUdpData(sendpack, to: "255.255.255.255", on: UDP_PORT)
    }
    
    // MARK: - UDP 代理回调方法实现
    
    /// 连接成功回调
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        lisener?.notified(with: "updsocket 连接成功")
    }
    
    /// 连接失败回调
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print(#function)
    }
    
    /// 发送数据成功回调
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print(#function)
        lisener?.notified(with: "udp data sent succesfully")
    }
    
    /// 发送数据失败回调
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print(#function)
    }
    
    /// 接受数据成功回调
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        print(#function)
        
        // TODO: 解密数据
        
        let decryptedData = decryptData(data: data)
 
        searchDeviceDataHandler(data: decryptedData, from: address)
    }
    
    /// 关闭成功回调
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print(#function, "\(error)")
        lisener?.notified(with: "UdpSocket关闭了")
    }
}

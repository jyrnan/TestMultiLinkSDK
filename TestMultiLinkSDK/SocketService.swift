//
//  TestClass.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/5.
//

import CocoaAsyncSocket
import Foundation



/// 作为对底层的封装，可以实现SDK作用
public class SocketService: NSObject {
    // MARK: - 变量
    
    let UDP_PORT:UInt16       = 8000; // udp 端口
    let UDP_COMMON_PORT:UInt16 = 8066; //通用版 UDP端口
    let UDP_LISTEN_PORT:UInt16 = 8009; // UDP监听电视端口

    public var serviceKey = "serviceKey"

    // 服务端和客户端的socket引用
    /// 如果作为Server端，则该socket必须创建作为监听作用
    /// 如果作为Client端，则该socket无需创建
    public var tcpSocketServer: GCDAsyncSocket?
    
    /// 作为Server端时，该socket表示当前Socket，也就是即将用作发送信息的socket
    /// 作为Client端时，该socket表示客户端socket
    public var tcpSocketClient: GCDAsyncSocket?
    
    /// 作为Server端时保存的在线的socket连接
    /// 作为客户端时能否也保存多个对不同server端的连接呢？
    var tcpSockets: [GCDAsyncSocket] = []
    
    /// 当前udpSocket端
    public var udpSocket: GCDAsyncUdpSocket?
    
    /// 当前可以连接的设备信息
    public var devices: [DeviceInfo] = []
    
    /// 当前的监听者
    public var lisener: Listener?
    
    public var isTcpConnected: Bool {checkTcpConnected()}
    public var isUdpListening: Bool {checkUdpListen()}


    // MARK: - 初始化方法

    public init(key: String = "serviceKey") {
        self.serviceKey = key
    }

    // MARK: - 外部调用方法

    public func initSDK(key: String) {}
    public func searchDeviceInfo(searchListener: Listener) {}
    public func createTcpChannel(info: DeviceInfo) -> Bool { return true }
    public func sendTcpData(data: Data) {}
    public func receiveTcpData(TCPListener: Listener) {
        self.lisener = TCPListener
    }
    public func closeTcpChannel() {}
    public func createUdpChannel(info: DeviceInfo) -> Bool { return true }
    public func sendGeneralCommand(command: String, data: KEYData) {}
    public func modifyDeviceName(name: String) {}
    
    //MARK: - 内部状态方法
    private func checkTcpConnected() -> Bool {
        guard let tcpSocket = tcpSocketClient else {return false}
        return tcpSocket.isConnected
    }
    
    private func checkUdpListen() -> Bool {
        guard let udpSocket = udpSocket else {return false}
        return udpSocket.localPort() != 0
    }
}



// MARK: - TCP

extension SocketService: GCDAsyncSocketDelegate {
    // MARK: - TCPClient
    
    /// 创建一个客户端socket，并建立和服务器连接
    /// - Parameters:
    ///   - ip: 服务器的ip地址
    ///   - port: 服务器的端口号
    /// - Returns: 返回是否建立连接成功的判定值
    public func connectToHost(_ ip: String, on port: String) -> Bool {
        if tcpSocketClient == nil {
            tcpSocketClient = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        }
        
        do {
            try tcpSocketClient?.connect(toHost: ip, onPort: UInt16(port)!)
            print("连接成功")
            lisener?.notified(with: "连接成功")
            return true
        } catch {
            print("连接失败: \(error)")
            lisener?.notified(with: "连接失败: \(error)")
            return false
        }
    }
    
    /// 从客户端方向断开连接
    public func closeTCPChannel() {
        guard let socket = tcpSocketClient else { return }
        socket.disconnect()
        print("断开连接")
        lisener?.notified(with: "断开连接")
    }

    // TODO: - 心跳方法
   
    // MARK: - TCPServer
   
    /// 监听
    public func listeningOn(port: String) -> Bool {
        tcpSocketServer = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)

        do {
            try tcpSocketServer?.accept(onPort: UInt16(port)!)
            print("监听成功")
            lisener?.notified(with: "监听成功")
            return true
            
        } catch {
            print("监听失败: \(error)")
            tcpSocketServer = nil
            return false
        }
    }
    
    // MARK: - TCP Common
    
    /// 发送数据
    /// - Parameter data: 需要发送的数据
    public func sendTCPData(data: Data?) {
        guard let socket = tcpSocketClient else { return }
        socket.write(data, withTimeout: -1, tag: 0)
    }

    // MARK: - TCP 代理回调方法实现
    
    /// 接收到新的Socket连接时的代理回调
    /// - Parameters:
    ///   - sock:
    ///   - newSocket:
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("连接成功")
        print("连接地址" + newSocket.connectedHost!)
        print("端口号 \(newSocket.connectedPort)")
        tcpSocketClient = newSocket
        
        // 第一次开始读取Data
        tcpSocketClient!.readData(withTimeout: -1, tag: 0)
    }
    
    /// 连接到新的Socket时的代理回调
    /// - Parameters:
    ///   - sock: <#sock description#>
    ///   - host: <#host description#>
    ///   - port: <#port description#>
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("连接到服务器：" + host)
        tcpSocketClient?.readData(withTimeout: -1, tag: 0)
    }
    
    /// TCPSocket收到数据的代理回调
    /// - Parameters:
    ///   - sock: <#sock description#>
    ///   - data: <#data description#>
    ///   - tag: <#tag description#>
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let message = String(data: data, encoding: .utf8)
        print(message ?? "")
        
        lisener?.deliver(data: data)
        
        // 再次准备读取Data,以此来循环读取Data
        sock.readData(withTimeout: -1, tag: 0)
    }
}

// MARK: - UDP

extension SocketService: GCDAsyncUdpSocketDelegate {
    // MARK: - UDPClient
    
    /// 创建UDP
    /// - Parameter port: <#port description#>
    public func createUdpSocket(on port: String) {
        closeUdpSocket()
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
        
        do {
            try udpSocket?.bind(toPort: UInt16(port) ?? UDP_PORT)
            try udpSocket?.enableBroadcast(true)
            try udpSocket?.beginReceiving()
            print("udp信道开始了")
            lisener?.notified(with: "UPD监听开始了，端口号：\(udpSocket?.localPort())")
            
        } catch {
            // 出错了，关闭socket
            udpSocket?.close()
            udpSocket = nil
            print("socket error: \(error)")
            lisener?.notified(with: "socket error: \(error)")
        }
    }
    
    public func closeUdpSocket() {
        guard let udpSocket = self.udpSocket else {return}
        udpSocket.close()
        self.udpSocket = nil
    }
    
    public func sendUdpData(_ data: Data, to host: String, on port: String) {
        udpSocket?.send(data, toHost: host, port: UInt16(port)!, withTimeout: -1, tag: 0)
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
        lisener?.deliver(data: data)
    }
    
    /// 关闭成功回调
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print(#function)
        lisener?.notified(with: "UdpSocket关闭了")
    }
}

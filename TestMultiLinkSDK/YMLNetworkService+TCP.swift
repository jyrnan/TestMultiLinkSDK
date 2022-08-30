//
//  YMLNetworkService+TCP.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/18.
//

import CocoaAsyncSocket
import Foundation

extension YMLNetworkService: GCDAsyncSocketDelegate {
    // MARK: - TCPClient
    
    /// 创建一个客户端socket，并建立和服务器连接
    /// - Parameters:
    ///   - ip: 服务器的ip地址
    ///   - port: 服务器的端口号
    /// - Returns: 返回是否建立连接成功的判定值
    public func connectToHost(_ ip: String, on port: UInt16) -> Bool {
        if tcpSocketClient == nil {
            tcpSocketClient = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        }
        
        if isTcpConnected {
            closeTCPChannel()
        }
        
        do {
            try tcpSocketClient?.connect(toHost: ip, onPort: port)
            print("tcp连接成功")
            isTcpConnected = true
            lisener?.notified(with: "tcp连接成功")
            return true
        } catch {
            print("tcp连接失败: \(error)")
            lisener?.notified(with: "tcp连接失败: \(error)")
            updateHasConnectedToDevice()
            return false
        }
    }
    
    /// 从客户端方向断开连接
    public func closeTCPChannel() {
        guard let socket = tcpSocketClient else { return }
        socket.disconnect()
        print("tcp断开连接")
        lisener?.notified(with: "tcp断开连接")
    }

    // TODO: - 心跳方法
   
    // MARK: - TCPServer
   
    /// 监听
    public func listeningOn(port: String) -> Bool {
        tcpSocketServer = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)

        do {
            try tcpSocketServer?.accept(onPort: UInt16(port)!)
            print("监听成功")
            isTcpListening = true
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
        print(#line, #function, "\n接受TCP连接成功." + "连接地址: " + newSocket.connectedHost! + " 端口号: \(newSocket.connectedPort)")
        
        // 第一次开始读取Data
        newSocket.readData(withTimeout: -1, tag: 0)
    }
    
    /// 连接到新的Socket时的代理回调
    /// - Parameters:
    ///   - sock: <#sock description#>
    ///   - host: <#host description#>
    ///   - port: <#port description#>
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("连接到TCP服务器：" + host)
        print(#line, #function, tcpSocketClient?.isConnected)
        tcpSocketClient?.readData(withTimeout: -1, tag: 0)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        switch sock {
        case tcpSocketServer:
            isTcpListening = false
        case tcpSocketClient:
            isTcpConnected = false
        default:
            return
        }
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

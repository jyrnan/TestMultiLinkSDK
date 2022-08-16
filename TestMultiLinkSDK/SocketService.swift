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
    
    public let UDP_PORT:UInt16       = 8000; // udp 端口
    public let UDP_COMMON_PORT:UInt16 = 8066; //通用版 UDP端口
    public let UDP_LISTEN_PORT:UInt16 = 8009; // UDP监听电视端口

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
    public var foundDevices: [DeviceInfo] = []
    
    ///当前连接的设备
    public var hasConnectedToDevice: DeviceInfo? = nil
    
    /// 当前的监听者
    public var lisener: Listener?
    
    ///作为TCP服务器端是否开始监听
    public var isTcpListening: Bool {checkTcpServerListen()}
    ///作为TCP客户端是否连接到服务器
    public var isTcpConnected: Bool {checkTcpClientConnected()}
    ///作为UDP客户端是否启动并有监听端口，可能是系统随机分配
    public var isUdpListening: Bool {checkUdpClientListen()}


    // MARK: - 初始化方法

//    public init(key: String = "serviceKey") {
//        self.serviceKey = key
//
//    }
    
    

    // MARK: - 外部调用方法

    public func initSDK(key: String) {
        self.serviceKey = key
    }
    
    public func searchDeviceInfo(searchListener: Listener) {
        lisener = searchListener
        searchDevice()
    }
    public func createTcpChannel(info: DeviceInfo) -> Bool {
        //TODO: -
        return true }
    public func sendTcpData(data: Data) {
        //TODO: -
    }
    public func receiveTcpData(TCPListener: Listener) {
        self.lisener = TCPListener
    }
    public func closeTcpChannel() {
        //TODO: -
    }
    
    /// 建立一个UdpSoket，设置
    /// - Parameter info: 建立连接的设备信息
    /// - Returns: 返回连接建立状况
    public func createUdpChannel(info: DeviceInfo) -> Bool {
        hasConnectedToDevice = info
        return setupUdpSocket(on: UDP_LISTEN_PORT)
    }
    
    public func sendGeneralCommand(command: String, data: KEYData) {}
    public func modifyDeviceName(name: String) {}
    
    //MARK: - 内部状态方法
    private func checkTcpServerListen() -> Bool {
        guard let tcpServer = tcpSocketServer else {return false}
        return tcpServer.isConnected
    }
    
    private func checkTcpClientConnected() -> Bool {
        guard let tcpClient = tcpSocketClient else {return false}
        return tcpClient.isConnected
    }
    
    private func checkUdpClientListen() -> Bool {
        guard let udpClient = udpSocket else {return false}
        return udpClient.localPort() != 0
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
    
    
    /// 建立UDP信道
    /// - Parameter port: 指定监听的端口号
    /// - Returns: 返回状态
    public func setupUdpSocket(on port: UInt16? = nil) -> Bool {
        closeUdpSocket()
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
        
        do {
            //如果有输入端口号才监听指定端口号;
            if let port {
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
    
    
    public func closeUdpSocket() {
        guard let udpSocket = self.udpSocket else {return}
        udpSocket.close()
        self.udpSocket = nil
    }
    
    public func sendUdpData(_ data: Data, to host: String, on port: UInt16) {
        udpSocket?.send(data, toHost: host, port: port, withTimeout: -1, tag: 0)
    }
    
    
    /// 发送广播获取局域网内电视信息
    private func searchDevice() {
        
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
 
        searchDeviceDataHandler(data: data, from: address)
        
        
    }
    
    /// 关闭成功回调
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print(#function, "\(error)")
        lisener?.notified(with: "UdpSocket关闭了")
    }
}

//MARK: - 数据处理
extension SocketService {
    
    /// 创建并返回用于搜索局域网设备的UDP广播包
    /// - Parameter device: 发出搜寻包的设备信息
    /// - Returns:带有搜寻设备名称信息的广播包数据
    private func makeSeachDeviceSendPack(with device:DeviceInfo? = nil) -> Data {
        var sendPack: Data = Data(capacity: 50)
        let devicename:Data = (device?.name ?? "UnamedDevice").data(using: .utf8)!
        var length: UInt16 = UInt16(devicename.count + 8).bigEndian
        let nsdata_length = Data(bytes: &length, count: MemoryLayout.size(ofValue: length))
        
        sendPack.append(nsdata_length)
        sendPack.append(contentsOf: [0x00,0x70]) //包命令值
        sendPack.append(contentsOf: [0x00,0x00,0x00,0x00]) //Service_id保留字段
        sendPack.append(contentsOf: [0x00,0x08]) //协议版本
        sendPack.append(contentsOf: [0x01,0x01]) //平台类型： iOS
        sendPack.append(devicename) // 不包含包命令值的数据总长度：DeviceName长度 + 8
        
        return sendPack
    }
}

//MARK: - 设备查找
extension SocketService {
    
    private func searchDeviceDataHandler(data: Data, from address: Data) {
        var ip: NSString?
        var port: UInt16 = 0
        GCDAsyncSocket.getHost(&ip, port: &port, fromAddress: address)
        
        var sdkVersion: String
        var platform: String
        
        guard data.count > 12 else {return}
        
        sdkVersion = data[8...9].map{String(format: "%02x", $0)}.joined()
        platform = data[10...11].map{String(format: "%02x", $0)}.joined()
        
        guard let deviceName = String(data: data[12...], encoding: .utf8) else {return}
        
        let device = DeviceInfo(name: deviceName, platform: platform, ip: ip! as String, sdkVersion: sdkVersion)
        
        recieveOneDevice(device: device)
        
    }
    
    private func recieveOneDevice(device: DeviceInfo) {
        
        print("--------- Technology research UDP did receive data \(device.description)-----------------")
        
        if device.platform == "21" || device.platform == "02ff" { //如果是电视？
            if !isContainsDevice(device: device) {
                addDevice(device: device)
                
                lisener?.deliver(devices: foundDevices)
            }
        }
        
        if !isTcpConnected {
            //TODO: - 建立连接到该设备TCP连接
        }
    }
    
    private func isContainsDevice(device: DeviceInfo) -> Bool {
        return foundDevices.contains {
            return device.ip == $0.ip  && device.name == $0.name
        }
    }
    
    private func addDevice(device: DeviceInfo) {
        if !self.isContainsDevice(device: device) {
            foundDevices.append(device)
        }
    }
    
    private func clearDevices() {
        return foundDevices.removeAll()
    }
}
	

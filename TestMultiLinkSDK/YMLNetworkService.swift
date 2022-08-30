//
//  TestClass.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/5.
//

import CocoaAsyncSocket
import Foundation

/// 作为对底层的封装，可以实现SDK作用
public class YMLNetworkService: NSObject {
    // MARK: - 变量
    
    public let UDP_PORT: UInt16 = 8000 // udp 端口
    public let UDP_COMMON_PORT: UInt16 = 8066 // 通用版 UDP端口
    public let UDP_LISTEN_PORT: UInt16 = 8009 // UDP监听电视端口

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
    public var discoveredDevice: [DiscoveryInfo] = []
    
    /// 当前连接的设备
    public var hasConnectedToDevice: DeviceInfo?
    
    /// 当前的监听者
    public var lisener: Listener?
    
    /// 作为TCP服务器端是否开始监听
    public var isTcpListening: Bool = false //{ checkTcpServerListen() }
    
    /// 作为TCP客户端是否连接到服务器
    public var isTcpConnected: Bool = false //{ checkTcpClientConnected() }
    
    /// 作为UDP客户端是否启动并有监听端口，可能是系统随机分配
    public var isUdpListening: Bool { checkUdpClientListen() }

    // MARK: - 外部调用方法

    public func initSDK(key: String) {
        serviceKey = key
    }
    
    public func searchDeviceInfo(searchListener: Listener) {
        lisener = searchListener
        searchDevice()
    }
    
    public func createTcpChannel(info: DeviceInfo) -> Bool {
        // TODO: -
        
        guard let discoveryInfo = discoveredDevice.filter({ $0.device.ip == info.ip }).first else { return false }
        updateHasConnectedToDevice(with: info) //先设置成当前设备，如果后续失败会更改相应设置
        return connectToHost(info.ip, on: discoveryInfo.TcpPort)
    }

    public func sendTcpData(data: Data) {
        // TODO: -
    }

    public func receiveTcpData(TCPListener: Listener) {
        lisener = TCPListener
    }

    public func closeTcpChannel() {
        // TODO: -
    }
    
    /// 建立一个UdpSoket，设置
    /// - Parameter info: 建立连接的设备信息
    /// - Returns: 返回连接建立状况
    public func createUdpChannel(info: DeviceInfo) -> Bool {
        
        return setupUdpSocket(on: UDP_LISTEN_PORT)
    }
    
    /// 通过Udp发送通用命令
    /// - Parameters:
    ///   - command: 命令类型
    ///   - data: 命令数据
    /// - Returns: 发送是否成功？
    public func sendGeneralCommand(command: String, data: KEYData) -> Bool {
        guard let device = hasConnectedToDevice else { return false }
        guard let port = discoveredDevice.filter({ $0.device.ip == device.ip }).first?.UdpPort else { return false }
        
        let sendPack = makeGeneralCommandSendPack(with: command, and: data)
        let sendPack2 = makeSeachDeviceSendPack()
        sendUdpData(sendPack2, to: "255.255.255.255", on: port)
        
        return true
    }
    
    public func modifyDeviceName(name: String) {}
    
    // MARK: - 内部状态方法

    private func checkTcpServerListen() -> Bool {
        guard let tcpServer = tcpSocketServer else { return false }
        return tcpServer.isConnected
    }
    
    private func checkTcpClientConnected() -> Bool {
        guard let tcpClient = tcpSocketClient else { return false }
        print(#line, #function, tcpClient )
        return  tcpClient.isConnected
    }
    
    private func checkUdpClientListen() -> Bool {
        guard let udpClient = udpSocket else { return false }
        return udpClient.localPort() != 0
    }
    
    func updateHasConnectedToDevice(with info: DeviceInfo? = nil) {
        hasConnectedToDevice = info
    }
}

// MARK: - 数据处理

extension YMLNetworkService {
    // TODO: - 加密解密数据方法
    func encryptData(data: Data) -> Data {
        return data
    }
    
    func decryptData(data: Data) -> Data {
        return data
    }
    
    private func makeGeneralCommandSendPack(with command: String, and data: KEYData) -> Data {
        var sampleMouseMoveData = Data(capacity: 11)
        sampleMouseMoveData.append(contentsOf: [0x00, 0x07, 0x10, 0x04])
        sampleMouseMoveData.append(contentsOf: [0x01])
        sampleMouseMoveData.append(contentsOf: [0x00, 0x01, 0x00, 0x01])
        sampleMouseMoveData.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        
        return sampleMouseMoveData
    }
    
    /// 创建并返回用于搜索局域网设备的UDP广播包
    /// - Parameter device: 发出搜寻包的设备信息
    /// - Returns:带有搜寻设备名称信息的广播包数据
    func makeSeachDeviceSendPack(with device: DeviceInfo? = nil) -> Data {
        var sendPack = Data(capacity: 50)
        let devicename: Data = (device?.name ?? "UnamedDevice").data(using: .utf8)!
        var length = UInt16(devicename.count + 8).bigEndian
        let nsdata_length = Data(bytes: &length, count: MemoryLayout.size(ofValue: length))
        
        sendPack.append(nsdata_length)
        sendPack.append(contentsOf: [0x00, 0x70]) // 包命令值
        sendPack.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Service_id保留字段
        sendPack.append(contentsOf: [0x00, 0x08]) // 协议版本
        sendPack.append(contentsOf: [0x01, 0x01]) // 平台类型： iOS
        sendPack.append(devicename) // 不包含包命令值的数据总长度：DeviceName长度 + 8
        
        return sendPack
    }
}

// MARK: - 设备查找

extension YMLNetworkService {
    /// 处理发送设备搜寻广播后收到的UDP数据
    /// - Parameters:
    ///   - data: 收到的UDP数据（默认加密）
    ///   - address: UDP数据发送方地址信息
    func searchDeviceDataHandler(data: Data, from address: Data) {
        var ip: NSString?
        var port: UInt16 = 0
        GCDAsyncSocket.getHost(&ip, port: &port, fromAddress: address)
        
        var sdkVersion: String
        var platform: String
        
        guard data.count > 12 else { return }
        
        sdkVersion = data[8...9].map { String(format: "%02x", $0) }.joined()
        platform = data[10...11].map { String(format: "%02x", $0) }.joined()
        
        guard let deviceName = String(data: data[12...], encoding: .utf8) else { return }
        
        let device = DeviceInfo(name: deviceName, platform: platform, ip: ip! as String, sdkVersion: sdkVersion)
        
        // TODO: - 增加获取TCP和UDP端口
        
        let tcpPort: UInt16 = UDP_PORT + 1 // 某个端口
        let udpPort: UInt16 = UDP_PORT
        
        let discoveredInfo: DiscoveryInfo = .init(device: device, TcpPort: tcpPort, UdpPort: udpPort)
        
        recieveOneDevice(info: discoveredInfo)
    }
    
    private func recieveOneDevice(info: DiscoveryInfo) {
        print("--------- Technology research UDP did receive data \(info.device.description)-----------------")
        
        if info.device.platform == "21" || info.device.platform == "02ff" { // 如果是电视？
            if !isContainsDevice(device: info.device) {
                addDiscovery(info: info)
                
                let devices = discoveredDevice.map(\.device)
                lisener?.deliver(devices: devices)
            }
        }
        
        if !isTcpConnected {
            // TODO: - 建立连接到该设备TCP连接
        }
    }
    
    private func isContainsDevice(device: DeviceInfo) -> Bool {
        return discoveredDevice.map(\.device).contains {
            return device.ip == $0.ip && device.name == $0.name
        }
    }
    
    private func addDiscovery(info: DiscoveryInfo) {
        if !isContainsDevice(device: info.device) {
            discoveredDevice.append(info)
        }
    }
    
    private func clearDiscoveredDevice() {
        return discoveredDevice.removeAll()
    }
}
	

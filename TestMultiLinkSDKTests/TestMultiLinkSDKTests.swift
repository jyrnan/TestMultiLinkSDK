//
//  TestMultiLinkSDKTests.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/5.
//

@testable import TestMultiLinkSDK
import XCTest

final class TestMultiLinkSDKTests: XCTestCase {
    var sut: YMLNetworkService!
    var mockServer: MockUdpServer!
    
    let willSentData: Data = "TestData".data(using: .utf8)!
    
    var localDevice: DeviceInfo = .init(name: "LocalDevice")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        
        sut = YMLNetworkService()
        
        mockServer = MockUdpServer()
        _ = mockServer.setupServer()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
        
        mockServer.udpSocket?.close()
        mockServer.udpSocket = nil
        mockServer = nil
        
        sut.udpSocket?.close()
        sut.udpSocket = nil
        sut = nil
    }
    
    fileprivate func randomValidPort() -> UInt16 {
        let minPort = UInt32(1024)
        let maxPort = UInt32(UINT16_MAX)
        let value = maxPort - minPort + 1
        return UInt16(minPort + arc4random_uniform(value))
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testInitSDK() {
        sut.initSDK(key: "TestClientName")
        XCTAssertEqual(sut.serviceKey, "TestClientName")
        XCTAssertNil(sut.tcpSocketServer)
        XCTAssertNil(sut.tcpSocketClient)
        XCTAssertTrue(sut.tcpSockets.isEmpty)
        XCTAssertNil(sut.udpSocket)
        
        XCTAssertTrue(sut.discoveredDevice.isEmpty)
        XCTAssertNil(sut.hasConnectedToDevice)
        
        XCTAssertFalse(sut.isTcpListening)
        XCTAssertFalse(sut.isTcpConnected)
        XCTAssertFalse(sut.isUdpListening)
    }
    
    func testCloseUdpSocket() {
        sut.closeUdpSocket()
        XCTAssertFalse(sut.isUdpListening)
        XCTAssertNil(sut.udpSocket)
    }
    
    func testSetupUdpSocketWithNoPort() {
        sut.closeUdpSocket()
        
        let result = sut.setupUdpSocket(on: nil)
        
        XCTAssertNotNil(sut.udpSocket)

        switch result {
        case true:
            XCTAssertFalse(sut.isUdpListening)
        case false:
            XCTAssertFalse(sut.isUdpListening)
        }
    }
    
    func testSetupUdpSocketWithRandomPort() {
        sut.closeUdpSocket()
        
        let port = randomValidPort()
        let result = sut.setupUdpSocket(on: port)
        
        XCTAssertNotNil(sut.udpSocket)
        
        switch result {
        case true:
            XCTAssertTrue(sut.isUdpListening)
        case false:
            XCTAssertFalse(sut.isUdpListening)
        }
    }
    
    func testSetupUdpSocketWithOccupiedPort() {
        sut.closeUdpSocket()
        let port: UInt16 = 80
        
        let sut2 = YMLNetworkService()
        guard sut2.setupUdpSocket(on: 80) else {
            XCTFail("创建端口占用未成功，测试失败")
            return
        }
        
        let result = sut.setupUdpSocket(on: port)
        
        XCTAssertFalse(result)
        XCTAssertNil(sut.udpSocket)
        XCTAssertFalse(sut.isUdpListening)
    }

    func testSearchDeciceInfo() {
        let expectation = XCTestExpectation(description: "测试获得查找结果")
        var mockListener = MockListener(verifyData: willSentData)
        
        let didDeliverDeciceInfo = {
            expectation.fulfill()
        }
        
        mockListener.onDeliverDeviceInfo = didDeliverDeciceInfo
        
        guard sut.setupUdpSocket(on: sut.UDP_LISTEN_PORT) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
        
        sut.searchDeviceInfo(searchListener: mockListener)
                
        wait(for: [expectation], timeout: 1)
    }
    
    func testSendGeneralCommand() {
        let expectation = XCTestExpectation(description: "测试发送通用命令")
        let didSendGeneralCommand = {
            expectation.fulfill()
        }
        
        mockServer.didSendGeneralCommand = didSendGeneralCommand
        
        guard sut.setupUdpSocket(on:sut.UDP_LISTEN_PORT) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
                
        let localDevice = DeviceInfo(ip: "127.0.0.1")
        let localDiscoveryInfo = DiscoveryInfo(device: localDevice, TcpPort: 8000, UdpPort: 8000)
        sut.discoveredDevice.append(localDiscoveryInfo)
        sut.hasConnectedToDevice = localDevice
        
        XCTAssertTrue(sut.sendGeneralCommand(command: "Mouse", data: KEYData()))
        
        wait(for: [expectation], timeout: 1)
    }
}

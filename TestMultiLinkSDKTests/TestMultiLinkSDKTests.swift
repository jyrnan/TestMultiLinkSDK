//
//  TestMultiLinkSDKTests.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/5.
//

import XCTest
@testable import TestMultiLinkSDK

final class TestMultiLinkSDKTests: XCTestCase {
    
    var sut: SocketService!
    let willSentData: Data = "TestData".data(using: .utf8)!
    
    var localDevice:  DeviceInfo = DeviceInfo(name:"LocalDevice")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        
        sut = SocketService()
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        self.measure {
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
        
        XCTAssertTrue(sut.foundDevices.isEmpty)
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

    func testSearchDeciceInfo() {
        
        let expectation = XCTestExpectation(description: "测试获得查找结果")
        var mockListener = MockListener(verifyData:willSentData)
        
        let didDeliverDeciceInfo = {
            expectation.fulfill()
        }
        
        mockListener.onDeliverDeviceInfo = didDeliverDeciceInfo
        
        let mockUdpServer = MockUdpServer()
        _ = mockUdpServer.setupServer()
        
        guard sut.setupUdpSocket(on:sut.UDP_LISTEN_PORT) else {
            XCTFail("不能建立本地连接，测试失败")
            return
        }
        
        sut.searchDeviceInfo(searchListener: mockListener)
                
        wait(for: [expectation], timeout: 1)
    }
   
}

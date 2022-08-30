//
//  MockListener.swift
//  TestMultiLinkSDKTests
//
//  Created by Yong Jin on 2022/8/11.
//

import TestMultiLinkSDK
import XCTest

struct MockListener: Listener {
    
    typealias Callback = Optional<() -> Void>
    let verifyData: Data!

    var onDeliver: Callback = nil
    var onDeliverDeviceInfo: Callback = nil
    var onNotified: Callback = nil
    var onAccept: Callback = nil
    
    var expectation: XCTestExpectation? = nil
    
    var message: String = ""
    
    func deliver(data: Data) {
        if data == verifyData {
            self.onDeliver?()
        }
    }
    
    func deliver(devices: [DeviceInfo]) {
        print(#function)
        self.onDeliverDeviceInfo?()
    }
    
    func notified(with message: String) {
        self.onNotified?()
    }
    
}

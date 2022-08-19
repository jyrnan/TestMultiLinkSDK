//
//  KEYData.swift
//  TestMultiLinkSDK
//
//  Created by Yong Jin on 2022/8/7.
//

import Foundation

public struct KEYData {
    let x: Double = 0
    let y: Double = 0
    let z: Double = 0
    let speed: Double = 0
    var v: String?
    
    public init(v: String? = nil) {
        self.v = v
    }
}

//
//  File.swift
//  
//
//  Created by Adam Wulf on 10/20/21.
//

import XCTest

class ClockTests: XCTestCase {
    lazy var id1: Data = {
        var id = [UInt8](repeating: 0, count: 16)
        id[15] = 1
        return Data(id)
    }()

    lazy var id2: Data = {
        var id = [UInt8](repeating: 0, count: 16)
        id[15] = 2
        return Data(id)
    }()
}

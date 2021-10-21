//
//  File.swift
//  
//
//  Created by Adam Wulf on 10/20/21.
//

import XCTest
@testable import Clocks

class ClockTests: XCTestCase {
    lazy var id1: SimpleIdentifier = {
        var id = [UInt8](repeating: 0, count: SimpleIdentifier.requiredSize)
        id[SimpleIdentifier.requiredSize - 1] = 1
        return SimpleIdentifier(rawValue: Data(id))!
    }()

    lazy var id2: Identifier = {
        var id = [UInt8](repeating: 0, count: SimpleIdentifier.requiredSize)
        id[SimpleIdentifier.requiredSize - 1] = 2
        return SimpleIdentifier(rawValue: Data(id))!
    }()
}

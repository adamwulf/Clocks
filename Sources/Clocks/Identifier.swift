//
//  File.swift
//  
//
//  Created by Adam Wulf on 10/20/21.
//

import Foundation

public protocol Identifier {
    static var defaultIdentifier: Self { get }
    static var requiredSize: Int { get }
    init?(rawValue: Data)
    var rawValue: Data { get }
}

public extension Identifier {
    static func < (lhs: Identifier, rhs: Identifier) -> Bool {
        guard lhs.rawValue.count == rhs.rawValue.count else { fatalError() }
        return lhs.rawValue < rhs.rawValue
    }
    static func > (lhs: Identifier, rhs: Identifier) -> Bool {
        guard lhs.rawValue.count == rhs.rawValue.count else { fatalError() }
        return lhs.rawValue > rhs.rawValue
    }
    static func <= (lhs: Identifier, rhs: Identifier) -> Bool {
        guard lhs.rawValue.count == rhs.rawValue.count else { fatalError() }
        return lhs.rawValue <= rhs.rawValue
    }
    static func >= (lhs: Identifier, rhs: Identifier) -> Bool {
        guard lhs.rawValue.count == rhs.rawValue.count else { fatalError() }
        return lhs.rawValue >= rhs.rawValue
    }
}

struct SimpleIdentifier: Identifier {
    static let defaultIdentifier = SimpleIdentifier(rawValue: Data([UInt8].init(repeating: 0, count: Self.requiredSize)))!
    static let requiredSize: Int = 16
    let data: Data

    init?(rawValue: Data) {
        guard rawValue.count == Self.requiredSize else { return nil }
        data = rawValue
    }

    var rawValue: Data {
        return data
    }

    static func random() -> Identifier {
        return SimpleIdentifier(rawValue: Data.random(length: Self.requiredSize))!
    }
}

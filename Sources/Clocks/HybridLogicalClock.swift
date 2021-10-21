//
//  File.swift
//  
//
//  Created by Adam Wulf on 5/14/21.
//  Based on Jared Forsyth's work at https://jaredforsyth.com/posts/hybrid-logical-clocks/
//

import Foundation

public struct HybridLogicalClock<IdType: Identifier>: Clock {
    fileprivate var cachedDataValue = DataCache()
    public let milliseconds: UInt64
    public let count: UInt16
    public let id: Identifier

    // MARK: - Init

    public init() {
        let id = SimpleIdentifier.random()
        self.init(timestamp: Date().timeIntervalSince1970, count: 0, id: id)
    }

    public init(timestamp: TimeInterval = Date().timeIntervalSince1970, count: UInt16 = 0, id: Identifier? = nil) {
        self.init(milliseconds: timestamp.milliseconds, count: count, id: id)
    }

    public init(milliseconds: UInt64, count: UInt16 = 0, id: Identifier? = nil) {
        let id = id ?? SimpleIdentifier.random()
        self.milliseconds = milliseconds
        self.count = count
        self.id = id
    }

    // MARK: - Public

    public func tick(now: HybridLogicalClock = HybridLogicalClock(id: IdType.defaultIdentifier)) -> HybridLogicalClock {
        if now.milliseconds > milliseconds {
            return HybridLogicalClock(milliseconds: now.milliseconds, count: 0, id: id)
        }
        return HybridLogicalClock(milliseconds: milliseconds, count: count + 1, id: id)
    }

    public func tock(now: HybridLogicalClock = HybridLogicalClock(id: IdType.defaultIdentifier), other: HybridLogicalClock) -> HybridLogicalClock {
        if now.milliseconds > milliseconds && now.milliseconds > other.milliseconds {
            return HybridLogicalClock(milliseconds: now.milliseconds, count: 0, id: id)
        } else if milliseconds == other.milliseconds {
            return HybridLogicalClock(milliseconds: milliseconds, count: max(count, other.count) + 1, id: id)
        } else if milliseconds > other.milliseconds {
            return HybridLogicalClock(milliseconds: milliseconds, count: count + 1, id: id)
        } else {
            return HybridLogicalClock(milliseconds: other.milliseconds, count: other.count + 1, id: id)
        }
    }

    public static func distantPast() -> HybridLogicalClock {
        return HybridLogicalClock(milliseconds: 0, count: 0, id: IdType.defaultIdentifier)
    }

    public var distantPast: HybridLogicalClock {
        return HybridLogicalClock(milliseconds: 0, count: 0, id: id)
    }
}

let milliSize = MemoryLayout<UInt64>.size
let countSize = MemoryLayout<UInt16>.size

// MARK: - RawRepresentable
extension HybridLogicalClock: RawRepresentable {
    public typealias RawValue = Data

    public init?(rawValue: Data) {
        guard rawValue.count >= milliSize + countSize + IdType.requiredSize else { return nil }
        let bytes: [UInt8] = [UInt8](rawValue)
        let bigEndianMilli = bytes[0..<milliSize].withUnsafeBytes({ $0.load(as: UInt64.self) })
        let milliseconds = UInt64(bigEndian: bigEndianMilli)
        let bigEndianCount = bytes[milliSize..<milliSize + countSize].withUnsafeBytes({ $0.load(as: UInt16.self) })
        let count = UInt16(bigEndian: bigEndianCount)
        let idBytes: [UInt8] = Array(bytes[milliSize + countSize..<bytes.count])
        guard let id = IdType(rawValue: Data(idBytes)) else { return nil }

        self.milliseconds = milliseconds
        self.count = count
        self.id = id
    }

    public var rawValue: Data {
        if let cachedDataValue = cachedDataValue.cache {
            return cachedDataValue
        }
        var bytes: [UInt8] = []
        withUnsafeBytes(of: milliseconds) { pointer in
            // little endian by default on iOS/macOS, so reverse to get bigEndian
            bytes.append(contentsOf: pointer.reversed())
        }
        withUnsafeBytes(of: count) { pointer in
            // little endian by default on iOS/macOS, so reverse to get bigEndian
            bytes.append(contentsOf: pointer.reversed())
        }
        bytes.append(contentsOf: id.rawValue)

        let ret = Data(bytes)
        cachedDataValue.cache = ret
        return ret
    }
}

// MARK: - Comparable
extension HybridLogicalClock: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.milliseconds < rhs.milliseconds ||
        (lhs.milliseconds == rhs.milliseconds && lhs.count < rhs.count) ||
        (lhs.milliseconds == rhs.milliseconds && lhs.count == rhs.count && lhs.id.rawValue < rhs.id.rawValue)
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.milliseconds == rhs.milliseconds && lhs.count == rhs.count && lhs.id.rawValue == rhs.id.rawValue
    }
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return rhs < lhs
    }
}

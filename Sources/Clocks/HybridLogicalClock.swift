//
//  File.swift
//  
//
//  Created by Adam Wulf on 5/14/21.
//  Based on Jared Forsyth's work at https://jaredforsyth.com/posts/hybrid-logical-clocks/
//

import Foundation

public struct HybridLogicalClock: Clock {
    public typealias RawValue = String

    public let timestamp: TimeInterval
    public let count: Int
    public let id: String

    // MARK: - Init

    public init() {
        let id = String(String.uuid(prefix: "hlc").prefix(12))
        self.init(timestamp: Date().timeIntervalSince1970, count: 0, id: id)
    }

    public init(timestamp: TimeInterval = Date().timeIntervalSince1970, count: Int = 0, id: String? = nil) {
        self.timestamp = timestamp
        self.count = count
        self.id = id ?? String(String.uuid(prefix: "hlc").prefix(12))
    }

    // MARK: - Public

    public func tick(now: HybridLogicalClock = HybridLogicalClock()) -> HybridLogicalClock {
        if now.timestamp > timestamp {
            return HybridLogicalClock(timestamp: now.timestamp, count: 0, id: id)
        }
        return HybridLogicalClock(timestamp: timestamp, count: count + 1, id: id)
    }

    public func tock(now: HybridLogicalClock = HybridLogicalClock(), other: HybridLogicalClock) -> HybridLogicalClock {
        if now.timestamp > timestamp && now.timestamp > other.timestamp {
            return HybridLogicalClock(timestamp: now.timestamp, count: 0, id: id)
        } else if timestamp == other.timestamp {
            return HybridLogicalClock(timestamp: timestamp, count: max(count, other.count) + 1, id: id)
        } else if timestamp > other.timestamp {
            return HybridLogicalClock(timestamp: timestamp, count: count + 1, id: id)
        } else {
            return HybridLogicalClock(timestamp: other.timestamp, count: other.count + 1, id: id)
        }
    }

    public static func distantPast() -> HybridLogicalClock {
        return HybridLogicalClock(timestamp: 0, count: 0)
    }

    public var distantPast: HybridLogicalClock {
        return HybridLogicalClock(timestamp: 0, count: 0, id: id)
    }
}

// MARK: - RawRepresentable
extension HybridLogicalClock: RawRepresentable {
    public init?(rawValue: String) {
        guard
            case let comps = rawValue.split(separator: "-"),
            comps.count >= 3,
            let timestamp = TimeInterval(comps[0]),
            let count = Int(comps[1]),
            case let id = String(comps[2...].joined(separator: "-"))
        else {
            return nil
        }
        self.timestamp = timestamp
        self.count = count
        self.id = id
    }

    public var rawValue: String {
        return "\(timestamp)-\(count)-\(id)"
    }
}

// MARK: - Comparable
extension HybridLogicalClock: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return
            lhs.timestamp < rhs.timestamp ||
            (lhs.timestamp == rhs.timestamp && lhs.count < rhs.count) ||
            (lhs.timestamp == rhs.timestamp && lhs.count == rhs.count && lhs.id < rhs.id)
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.count == rhs.count && lhs.id == rhs.id
    }
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return rhs < lhs
    }
}

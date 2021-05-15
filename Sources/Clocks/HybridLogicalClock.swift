//
//  File.swift
//  
//
//  Created by Adam Wulf on 5/14/21.
//  Based on Jared Forsyth's work at https://jaredforsyth.com/posts/hybrid-logical-clocks/
//

import Foundation

public struct HybridLogicalClock: RawRepresentable, Equatable {
    public typealias RawValue = String

    let timestamp: TimeInterval
    let count: Int
    let id: String

    // MARK: - Init

    public init(timestamp: TimeInterval = Date.timeIntervalSinceReferenceDate, count: Int = 0, id: String? = nil) {
        self.timestamp = timestamp
        self.count = count
        self.id = id ?? String(String.uuid(prefix: "hlc").prefix(12))
    }

    // MARK: - RawRepresentable

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

    // MARK: - Public

    public func tick(timestamp now: TimeInterval = Date.timeIntervalSinceReferenceDate) -> HybridLogicalClock {
        if now > timestamp {
            return HybridLogicalClock(timestamp: now, count: 0, id: id)
        }
        return HybridLogicalClock(timestamp: timestamp, count: count + 1, id: id)
    }

    public func tock(timestamp now: TimeInterval = Date.timeIntervalSinceReferenceDate, other: HybridLogicalClock) -> HybridLogicalClock {
        if now > timestamp && now > other.timestamp {
            return HybridLogicalClock(timestamp: now, count: 0, id: id)
        } else if timestamp == other.timestamp {
            return HybridLogicalClock(timestamp: timestamp, count: max(count, other.count) + 1, id: id)
        } else if timestamp > other.timestamp {
            return HybridLogicalClock(timestamp: timestamp, count: count + 1, id: id)
        } else {
            return HybridLogicalClock(timestamp: other.timestamp, count: other.count + 1, id: id)
        }
    }

    public func tock(timestamp now: TimeInterval = Date.timeIntervalSinceReferenceDate,
                     others: [HybridLogicalClock]) -> HybridLogicalClock {
        guard let last = others.sorted().last else { return tick(timestamp: now) }
        return tock(timestamp: now, other: last)
    }
}

// MARK: - Comparable
extension HybridLogicalClock: Comparable {
    public static func < (lhs: HybridLogicalClock, rhs: HybridLogicalClock) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

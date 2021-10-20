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

    public let milliseconds: UInt64
    public let count: Int
    public let id: String

    // MARK: - Init

    public init() {
        let id = String(String.uuid(prefix: "hlc").prefix(12))
        self.init(timestamp: Date().timeIntervalSince1970, count: 0, id: id)
    }

    public init(timestamp: TimeInterval = Date().timeIntervalSince1970, count: Int = 0, id: String? = nil) {
        self.init(milliseconds: timestamp.milliseconds, count: count, id: id)
    }

    public init(milliseconds: UInt64, count: Int = 0, id: String? = nil) {
        self.milliseconds = milliseconds
        self.count = count
        self.id = id ?? String(String.uuid(prefix: "hlc").prefix(12))
    }

    // MARK: - Public

    public func tick(now: HybridLogicalClock = HybridLogicalClock(id: "Clocks.static")) -> HybridLogicalClock {
        if now.milliseconds > milliseconds {
            return HybridLogicalClock(milliseconds: now.milliseconds, count: 0, id: id)
        }
        return HybridLogicalClock(milliseconds: milliseconds, count: count + 1, id: id)
    }

    public func tock(now: HybridLogicalClock = HybridLogicalClock(id: "Clocks.static"), other: HybridLogicalClock) -> HybridLogicalClock {
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
        return HybridLogicalClock(milliseconds: 0, count: 0, id: "Clocks.static")
    }

    public var distantPast: HybridLogicalClock {
        return HybridLogicalClock(milliseconds: 0, count: 0, id: id)
    }
}

// MARK: - RawRepresentable
extension HybridLogicalClock: RawRepresentable {
    public init?(rawValue: String) {
        guard
            case let comps = rawValue.split(separator: "-"),
            comps.count >= 3,
            let milliseconds = UInt64(comps[0]),
            let count = Int(comps[1]),
            case let id = String(comps[2...].joined(separator: "-"))
        else {
            return nil
        }
        self.milliseconds = milliseconds
        self.count = count
        self.id = id
    }

    public var rawValue: String {
        return "\(milliseconds)-\(count)-\(id)"
    }
}

// MARK: - Comparable
extension HybridLogicalClock: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return
            lhs.milliseconds < rhs.milliseconds ||
            (lhs.milliseconds == rhs.milliseconds && lhs.count < rhs.count) ||
            (lhs.milliseconds == rhs.milliseconds && lhs.count == rhs.count && lhs.id < rhs.id)
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.milliseconds == rhs.milliseconds && lhs.count == rhs.count && lhs.id == rhs.id
    }
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return rhs < lhs
    }
}

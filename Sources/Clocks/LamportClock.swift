//
//  LamportClock.swift
//  
//
//  Created by Adam Wulf on 5/15/21.
//  Based on https://miafish.wordpress.com/2015/03/11/lamport-vector-clocks/
//

import Foundation

/// It follows some simple rules:
///
/// A process increments its counter before each event in that process;
/// When a process sends a message, it includes its counter value with the message;
/// On receiving a message, the receiver process sets its counter to be greater than the maximum
/// of its own value and the received value before it considers the message received.
public struct LamportClock: Clock {
    let count: UInt
    let id: String

    public init() {
        let id = String(String.uuid(prefix: "lam").prefix(12))
        self.init(count: 0, id: id)
    }

    public init(count: UInt = 0, id: String? = nil) {
        self.count = count
        self.id = id ?? String(String.uuid(prefix: "lam").prefix(12))
    }

    public func tick(now: LamportClock) -> LamportClock {
        return LamportClock(count: max(count, now.count) + 1, id: id)
    }

    public func tock(now: LamportClock, other: LamportClock) -> LamportClock {
        return LamportClock(count: max(count, max(now.count, other.count)) + 1, id: id)
    }
}

extension LamportClock: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        guard
            case let comps = rawValue.split(separator: "-"),
            comps.count >= 2,
            let count = UInt(comps[0]),
            case let id = String(comps[1...].joined(separator: "-"))
        else {
            return nil
        }
        self.init(count: count, id: id)
    }

    public var rawValue: String {
        return "\(count)-\(id)"
    }
}

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
    public static let defaultIdentifier: Identifier = SimpleIdentifier.defaultIdentifier
    fileprivate var cachedDataValue = DataCache()
    let count: UInt
    let id: Identifier

    public init() {
        let id = SimpleIdentifier()
        self.init(count: 1, id: id)
    }

    public init(count: UInt = 1, id: Identifier? = nil) {
        self.count = count
        self.id = id ?? SimpleIdentifier()
    }

    public func tick(now: LamportClock = LamportClock(id: Self.defaultIdentifier)) -> LamportClock {
        return LamportClock(count: max(count, now.count) + 1, id: id)
    }

    public func tock(now: LamportClock = LamportClock(id: Self.defaultIdentifier), other: LamportClock) -> LamportClock {
        return LamportClock(count: max(count, max(now.count, other.count)) + 1, id: id)
    }

    public static func distantPast() -> LamportClock {
        return LamportClock(count: 0)
    }

    public var distantPast: LamportClock {
        return LamportClock(count: 0, id: id)
    }
}

extension LamportClock: RawRepresentable {
    public typealias RawValue = Data

    static let countSize = MemoryLayout<UInt>.size
    static let idSize = 16 // 16 bytes for the device id

    public init?(rawValue: Data) {
        guard rawValue.count >= Self.countSize + Self.idSize else { return nil }
        let bytes: [UInt8] = [UInt8](rawValue)
        let bigEndianCount = bytes[0..<Self.countSize].withUnsafeBytes({ $0.load(as: UInt.self) })
        let count = UInt(bigEndian: bigEndianCount)
        let idBytes: [UInt8] = Array(bytes[Self.countSize..<bytes.count])
        guard idBytes.count == Self.idSize else { return nil }

        self.init(count: count, id: SimpleIdentifier(rawValue: Data(idBytes)))
    }

    public var rawValue: Data {
        if let cachedDataValue = cachedDataValue.cache {
            return cachedDataValue
        }
        var bytes: [UInt8] = []
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
extension LamportClock: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.count < rhs.count || (lhs.count == rhs.count && lhs.id.rawValue < rhs.id.rawValue)
    }
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.count == rhs.count && lhs.id.rawValue == rhs.id.rawValue
    }
    public static func > (lhs: Self, rhs: Self) -> Bool {
        return rhs < lhs
    }
}

//
//  File.swift
//  
//
//  Created by Adam Wulf on 5/15/21.
//  Based on https://miafish.wordpress.com/2015/03/11/lamport-vector-clocks/
//

import Foundation

/// It follows rules:
///
/// Initially all clocks are zero.
/// Each time a process experiences an internal event, it increments its own logical clock in the vector by one.
/// Each time a process prepares to send a message, it sends its entire vector along with the message being sent.
/// Each time a process receives a message, it increments its own logical clock in the vector by one and updates
/// each element in its vector by taking the maximum of the value in its own vector clock and the value in the vector
/// in the received message (for every element).
struct VectorClock: Clock {
    public static let defaultIdentifier: Data = Data([UInt8].init(repeating: 0, count: 16))
    fileprivate var cachedDataValue = DataCache()
    let count: UInt
    let id: Data
    let others: [Data: UInt]

    init() {
        self.init(count: 1, id: Data.random(length: 16))
    }

    init(count: UInt = 1, id: Data? = nil, others: [Data: UInt] = [:]) {
        self.count = count
        self.id = id ?? Data.random(length: 16)
        self.others = others
    }

    // MARK: - Public

    func tick(now: VectorClock) -> VectorClock {
        return VectorClock(count: count + 1, id: id, others: others)
    }

    func tock(now: VectorClock, other: VectorClock) -> VectorClock {
        let merged = asDictionary().merging(clock: other.asDictionary())
        return merged.clock(for: id).tick()
    }

    func tock(now: VectorClock, others clocks: [VectorClock]) -> VectorClock {
        let updated = clocks.reduce(asDictionary()) { result, clock in
            return result.merging(clock: clock.asDictionary())
        }
        return updated.clock(for: id).tick()
    }

    public static func distantPast() -> VectorClock {
        return VectorClock()
    }

    public var distantPast: VectorClock {
        return VectorClock(count: 0, id: id, others: others.mapValues({ _ in 0 }))
    }
}

extension VectorClock {
    func asDictionary() -> [Data: UInt] {
        return others.merging([id: count], uniquingKeysWith: { a, _ in a })
    }
}

extension Dictionary where Key == Data, Value == UInt {
    func merging(clock: [Data: UInt]) -> [Data: UInt] {
        var ret = self
        for (key, value) in clock {
            ret[key] = Swift.max(ret[key] ?? 0, value)
        }
        return ret
    }

    func clock(for id: Data) -> VectorClock {
        assert(keys.contains(id))
        var others = self
        let value = self[id]!
        others.removeValue(forKey: id)
        return VectorClock(count: value, id: id, others: others)
    }
}

extension VectorClock: RawRepresentable {
    public typealias RawValue = Data

    static let countSize = MemoryLayout<UInt>.size
    static let idSize = 16 // 16 bytes for the device id

    public init?(rawValue: Data) {
        guard rawValue.count >= Self.countSize + Self.idSize else { return nil }

        func vector(from: Data) -> (id: Data, count: UInt)? {
            guard rawValue.count == Self.countSize + Self.idSize else { return nil }
            let id = rawValue[0..<Self.idSize]
            let countBytes = [UInt8](rawValue[Self.idSize..<Self.countSize + Self.idSize])
            let bigEndianCount = countBytes.withUnsafeBytes({ $0.load(as: UInt.self) })
            let count = UInt(bigEndian: bigEndianCount)
            return (id: id, count: count)
        }

        guard let firstPair = vector(from: rawValue[0..<Self.countSize + Self.idSize]) else { return nil }

        let othersData = rawValue[Self.countSize + Self.idSize..<rawValue.count]
        var pairs: [Data: UInt] = [:]
        for i in stride(from: 0, to: othersData.count, by: Self.countSize + Self.idSize) {
            if let pair = vector(from: othersData[i..<i + Self.countSize + Self.idSize]) {
                pairs[pair.id] = pair.count
            }
        }
        self.init(count: firstPair.count, id: firstPair.id, others: pairs)
    }

    public var rawValue: Data {
        if let cachedDataValue = cachedDataValue.cache {
            return cachedDataValue
        }
        var bytes: [UInt8] = [UInt8](id)
        withUnsafeBytes(of: count) { pointer in
            // little endian by default on iOS/macOS, so reverse to get bigEndian
            bytes.append(contentsOf: pointer.reversed())
        }

        for key in others.keys.sorted(by: { $0 < $1 }) {
            guard let count = others[key] else { continue }

            bytes.append(contentsOf: key)
            withUnsafeBytes(of: count) { pointer in
                // little endian by default on iOS/macOS, so reverse to get bigEndian
                bytes.append(contentsOf: pointer.reversed())
            }
        }
        let ret = Data(bytes)
        cachedDataValue.cache = ret
        return ret
    }
}

fileprivate extension Array {
    func map<T>(pairs transform: (Element, Element) throws -> T) rethrows -> [T] {
        assert(self.count % 2 == 0, "Cannot map pairs of odd length array")
        var ret: [T] = []
        for i in 0..<self.count / 2 {
            try ret.append(transform(self[i * 2], self[i * 2 + 1]))
        }
        return ret
    }

    func compactMap<T>(pairs transform: (Element, Element) throws -> T?) rethrows -> [T] {
        return try map(pairs: transform).compactMap({ $0 })
    }
}

// MARK: - Comparable
infix operator <> : ComparisonPrecedence

extension VectorClock: Comparable {
    public static func < (lhs: VectorClock, rhs: VectorClock) -> Bool {
        let mine = lhs.asDictionary()
        let theirs = rhs.asDictionary()
        var hadLessThan = false
        for myClock in mine {
            guard let theirClock = theirs[myClock.key] else { continue }
            guard myClock.value <= theirClock else { return false }
            hadLessThan = hadLessThan || myClock.value < theirClock
        }
        return hadLessThan
    }

    public static func == (lhs: VectorClock, rhs: VectorClock) -> Bool {
        return lhs.asDictionary() == rhs.asDictionary()
    }

    public static func <> (lhs: VectorClock, rhs: VectorClock) -> Bool {
        return !(lhs < rhs) && !(rhs < lhs) && lhs != rhs
    }
}

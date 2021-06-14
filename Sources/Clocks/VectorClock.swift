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
    let count: UInt
    let id: String
    let others: [String: UInt]

    init() {
        self.init(count: 1, id: String(String.uuid(prefix: "vec").prefix(12)))
    }

    init(count: UInt = 1, id: String? = nil, others: [String: UInt] = [:]) {
        if id?.contains(":") ?? false {
            fatalError("Invalid Identifier. VectorClocks may not contain ':' in their id.")
        }
        self.count = count
        self.id = id ?? String(String.uuid(prefix: "vec").prefix(12))
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
    func asDictionary() -> [String: UInt] {
        return others.merging([id: count], uniquingKeysWith: { a, _ in a })
    }
}

extension Dictionary where Key == String, Value == UInt {
    func merging(clock: [String: UInt]) -> [String: UInt] {
        var ret = self
        for (key, value) in clock {
            ret[key] = Swift.max(ret[key] ?? 0, value)
        }
        return ret
    }

    func clock(for id: String) -> VectorClock {
        assert(keys.contains(id))
        var others = self
        let value = self[id]!
        others.removeValue(forKey: id)
        return VectorClock(count: value, id: id, others: others)
    }
}

extension VectorClock: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        guard
            case let comps = rawValue.split(separator: ":"),
            comps.count % 2 == 0,
            case let pairs = Self.parseIdCounts(from: rawValue),
            !pairs.isEmpty,
            var firstPair = pairs.first,
            case let lastPairs = pairs[1...],
            case let others: [String: UInt] = lastPairs.reduce([:], { result, pair in
                var result = result
                if pair.id == firstPair.id {
                    firstPair.count = max(pair.count, firstPair.count)
                } else {
                    let existing = result[pair.id] ?? 0
                    result[pair.id] = max(pair.count, existing)
                }
                return result
            })
        else {
            return nil
        }
        self.init(count: firstPair.count, id: firstPair.id, others: others)
    }

    public var rawValue: String {
        var othersStr = ""
        for key in others.keys.sorted() {
            guard let count = others[key] else { continue }
            if !othersStr.isEmpty {
                othersStr += ":"
            }
            othersStr += "\(key):\(count)"
        }
        if othersStr.isEmpty {
            return "\(id):\(count)"
        } else {
            return "\(id):\(count):\(othersStr)"
        }
    }
}

fileprivate extension VectorClock {
    static func parseIdCounts(from rawValue: String) -> [(id: String, count: UInt)] {
        if
            case let comps = rawValue.split(separator: ":"),
            comps.count % 2 == 0,
            case let pairs = comps.compactMap(pairs: { id, countStr -> (id: String, count: UInt)? in
                guard let count = UInt(countStr) else { return nil }
                return (id: String(id), count: count)
            }) {
            return pairs
        }
        return []
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

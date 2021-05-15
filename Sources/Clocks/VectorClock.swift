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
    let count: Int
    let id: String
    let others: [String: Int]

    init() {
        self.init(count: 0, id: String(String.uuid(prefix: "vec").prefix(12)))
    }

    init(count: Int = 0, id: String? = nil, others: [String: Int] = [:]) {
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
        var merged = others.merging(other.others) { mine, theirs in
            return max(mine, theirs)
        }
        let myMerged = merged[id] ?? 0
        merged.removeValue(forKey: id)
        return VectorClock(count: max(count, myMerged) + 1, id: id, others: merged)
    }

    func tock(now: VectorClock, others: [VectorClock]) -> VectorClock {
        return others.reduce(self) { result, other in
            return result.tock(other: other)
        }
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
            case let pairs = pairs[1...],
            case let others: [String: Int] = pairs.reduce([:], { result, pair in
                var result = result
                if pair.id == firstPair.id {
                    firstPair.count = max(pair.count, firstPair.count)
                } else {
                    let existing = result[pair.id] ?? 0
                    result[pair.id] = max(pair.count, existing)
                }
                return result
            }),
            !others.isEmpty
        else {
            return nil
        }
        self.init(count: firstPair.count, id: firstPair.id, others: others)
    }

    public var rawValue: String {
        return "\(count)-\(id)"
    }
}

fileprivate extension VectorClock {
    static func parseIdCounts(from rawValue: String) -> [(id: String, count: Int)] {
        if
            case let comps = rawValue.split(separator: ":"),
            comps.count % 2 == 0,
            case let pairs = comps.compactMap(pairs: { id, countStr -> (id: String, count: Int)? in
                guard let count = Int(countStr) else { return nil }
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

//
//  File.swift
//  
//
//  Created by Adam Wulf on 5/15/21.
//

import Foundation

public protocol Clock: RawRepresentable, Comparable {
    init()

    func tick(now: Self) -> Self

    func tock(now: Self, other: Self) -> Self

    func tock(now: Self, others: [Self]) -> Self

    static func distantPast() -> Self

    var distantPast: Self { get }
}

extension Clock {
    func tick() -> Self {
        return tick(now: Self())
    }

    func tock(other: Self) -> Self {
        return tock(now: Self(), other: other)
    }

    func tock(others: [Self]) -> Self {
        return tock(now: Self(), others: others)
    }

    public func tock(now: Self, others: [Self]) -> Self {
        guard let last = others.max() else { return tick(now: now) }
        return tock(now: now, other: last)
    }
}

//
//  HybridLogicalClockTests.swift
//  
//
//  Created by Adam Wulf on 5/14/21.
//

import XCTest
@testable import Clocks

final class HybridLogicalClockTests: XCTestCase {

    func testTick() throws {
        let clock1 = HybridLogicalClock()
        let clock2 = clock1.tick()

        XCTAssert(clock2.rawValue > clock1.rawValue)
        XCTAssert(clock2 > clock1)
    }

    func testReversingClock() throws {
        let now = HybridLogicalClock(timestamp: 0)
        let clock1 = HybridLogicalClock(timestamp: 1)
        let clock2 = HybridLogicalClock(timestamp: 2)
        // use a previous timestamp, and ensure that our ticked clocks are after existing timestamps
        let clock31 = clock1.tock(now: now, other: clock2)
        let clock32 = clock1.tock(now: now, others: [clock1, clock2])
        let clock33 = clock1.tock(now: now, others: [clock2, clock1])

        XCTAssert(clock2.rawValue > clock1.rawValue)
        XCTAssert(clock31.rawValue > clock2.rawValue)
        XCTAssert(clock31.id == clock1.id)
        XCTAssert(clock32.rawValue > clock2.rawValue)
        XCTAssert(clock32.id == clock1.id)
        XCTAssert(clock33.rawValue > clock2.rawValue)
        XCTAssert(clock33.id == clock1.id)
        XCTAssertEqual(clock31, clock32)
        XCTAssertEqual(clock32, clock33)
    }

    func testRawValue() throws {
        let now: TimeInterval = 1

        let clock1 = HybridLogicalClock(timestamp: now)

        XCTAssertEqual(clock1.rawValue, "\(now)-0-\(clock1.id)")
    }

    func testIncCount() throws {
        let now1 = HybridLogicalClock(timestamp: 1)
        let now2 = HybridLogicalClock(timestamp: 2)

        let clock1 = HybridLogicalClock(timestamp: now1.timestamp)
        let clock2 = clock1.tick(now: now1)
        let clock3 = clock2.tick(now: now2)

        XCTAssertEqual(clock1.rawValue, "\(now1.timestamp)-0-\(clock1.id)")
        XCTAssertEqual(clock2.rawValue, "\(now1.timestamp)-1-\(clock1.id)")
        XCTAssertEqual(clock3.rawValue, "\(now2.timestamp)-0-\(clock1.id)")
    }

    func testRawRepresentable() throws {
        let now: TimeInterval = 1
        let clock1 = HybridLogicalClock(timestamp: now, count: 0, id: "clock-1")
        let clock2 = HybridLogicalClock(timestamp: now, count: 0)

        XCTAssertEqual(clock1.rawValue, "\(now)-0-\(clock1.id)")
        XCTAssertEqual(clock2.rawValue, "\(now)-0-\(clock2.id)")

        let clock11 = HybridLogicalClock(rawValue: clock1.rawValue)
        let clock22 = HybridLogicalClock(rawValue: clock2.rawValue)

        XCTAssertEqual(clock1, clock11)
        XCTAssertEqual(clock2, clock22)
    }

    func testSort() throws {
        let id1 = "clock-1"
        let id2 = "clock-2"
        var clocks = [
            HybridLogicalClock(timestamp: 1, count: 0, id: id1),
            HybridLogicalClock(timestamp: 4, count: 0, id: id1),
            HybridLogicalClock(timestamp: 4, count: 1, id: id1),
            HybridLogicalClock(timestamp: 6, count: 0, id: id1),
            HybridLogicalClock(timestamp: 2, count: 0, id: id2),
            HybridLogicalClock(timestamp: 3, count: 0, id: id2),
            HybridLogicalClock(timestamp: 4, count: 0, id: id2),
            HybridLogicalClock(timestamp: 5, count: 0, id: id2),
        ]
        clocks.sort()

        // ensure clocks sort by timestamp, then by count, then by id
        for i in 1..<clocks.count {
            let prev = clocks[i - 1]
            let this = clocks[i]

            XCTAssert(prev.timestamp < this.timestamp ||
                        (prev.timestamp == this.timestamp &&
                            (prev.count < this.count ||
                                (prev.count == this.count && prev.id <= this.id))))
        }
    }
}

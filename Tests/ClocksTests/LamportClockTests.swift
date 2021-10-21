//
//  LamportClockTests.swift
//  
//
//  Created by Adam Wulf on 5/15/21.
//

import XCTest
@testable import Clocks

final class LamportClockTests: ClockTests {

    func testTick() throws {
        let clock1 = LamportClock()
        let clock2 = clock1.tick()

        XCTAssert(clock2.rawValue > clock1.rawValue)
        XCTAssert(clock2 > clock1)
    }

    func testReversingClock() throws {
        let now = LamportClock(count: 0)
        let clock1 = LamportClock(count: 1)
        let clock2 = LamportClock(count: 2)
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
        let now: UInt = 1

        let clock1 = LamportClock(count: now, id: id1)
        let clock2 = LamportClock(rawValue: clock1.rawValue)

        XCTAssertEqual(clock1.rawValue.hexString, "000000000000000100000000000000000000000000000001")
        XCTAssertEqual(clock1, clock2)
    }

    func testIncCount() throws {
        let now1 = LamportClock(count: 1)
        let now2 = LamportClock(count: 2)

        let clock1 = LamportClock(count: now1.count, id: id1)
        let clock2 = clock1.tick(now: now1)
        let clock3 = clock2.tick(now: now2)

        XCTAssertEqual(clock1.rawValue.hexString, "000000000000000100000000000000000000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "000000000000000200000000000000000000000000000001")
        XCTAssertEqual(clock3.rawValue.hexString, "000000000000000300000000000000000000000000000001")
    }

    func testRawRepresentable() throws {
        let now: UInt = 1
        let clock1 = LamportClock(count: now, id: id1)
        let clock2 = LamportClock(count: now, id: id2)

        XCTAssertEqual(clock1.rawValue.hexString, "000000000000000100000000000000000000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "000000000000000100000000000000000000000000000002")

        let clock11 = LamportClock(rawValue: clock1.rawValue)
        let clock22 = LamportClock(rawValue: clock2.rawValue)

        XCTAssertEqual(clock1, clock11)
        XCTAssertEqual(clock2, clock22)
    }

    func testSort() throws {
        var clocks = [
            LamportClock(count: 1, id: id1),
            LamportClock(count: 4, id: id1),
            LamportClock(count: 4, id: id1),
            LamportClock(count: 6, id: id1),
            LamportClock(count: 2, id: id2),
            LamportClock(count: 3, id: id2),
            LamportClock(count: 4, id: id2),
            LamportClock(count: 5, id: id2),
        ]
        clocks.sort()

        // ensure clocks sort by timestamp, then by count, then by id
        for i in 1..<clocks.count {
            let prev = clocks[i - 1]
            let this = clocks[i]

            XCTAssert(prev.count < this.count || (prev.count == this.count && prev.id <= this.id))
        }
    }

    func testComparable() throws {
        var clocks = [
            LamportClock(count: 1, id: id1),
            LamportClock(count: 4, id: id1),
            LamportClock(count: 4, id: id1),
            LamportClock(count: 6, id: id1),
            LamportClock(count: 2, id: id2),
            LamportClock(count: 3, id: id2),
            LamportClock(count: 4, id: id2),
            LamportClock(count: 5, id: id2),
        ]
        clocks.sort()

        // ensure clocks sort by timestamp, then by count, then by id
        for i in 1..<clocks.count {
            let prev = clocks[i - 1]
            let this = clocks[i]

            XCTAssert(prev.count < this.count || (prev.count == this.count && prev.id <= this.id))
        }
    }
}

//
//  VectorClockTests.swift
//  
//
//  Created by Adam Wulf on 5/15/21.
//

import XCTest
@testable import Clocks

final class VectorClockTests: XCTestCase {

    func testTick() throws {
        let clock1 = VectorClock(id: "A")
        let clock2 = clock1.tick()

        XCTAssert(clock2.rawValue > clock1.rawValue)
        XCTAssert(clock2 > clock1)
    }

    func testReversingClock() throws {
        let clock1 = VectorClock(count: 1, id: "A")
        let clock2 = VectorClock(count: 2, id: "B")
        // use a previous timestamp, and ensure that our ticked clocks are after existing timestamps
        let clock31 = clock1.tock(other: clock2)
        let clock32 = clock1.tock(others: [clock1, clock2])
        let clock33 = clock1.tock(others: [clock2, clock1])

        XCTAssertEqual(clock1.rawValue, "A:1")
        XCTAssertEqual(clock2.rawValue, "B:2")
        XCTAssertEqual(clock31.rawValue, "A:2:B:2")
        XCTAssertEqual(clock32.rawValue, "A:2:B:2")
        XCTAssertEqual(clock33.rawValue, "A:2:B:2")
    }

    func testRawValue() throws {
        let now: UInt = 1

        let clock1 = VectorClock(count: now)
        let clock2 = VectorClock(rawValue: clock1.rawValue)

        XCTAssertEqual(clock1.rawValue, "\(clock1.id):\(now)")
        XCTAssertEqual(clock1, clock2)
    }

    func testIncCount() throws {
        let clock1 = VectorClock(count: 0, id: "A")
        let clock2 = VectorClock(count: 0, id: "B")
        let clock3 = clock1.tick()
        let clock4 = clock3.tock(other: clock2)
        let clock5 = clock2.tock(other: clock4)

        XCTAssertEqual(clock1.rawValue, "A:0")
        XCTAssertEqual(clock2.rawValue, "B:0")
        XCTAssertEqual(clock3.rawValue, "A:1")
        XCTAssertEqual(clock4.rawValue, "A:2:B:0")
        XCTAssertEqual(clock5.rawValue, "B:1:A:2")
    }

    func testRawRepresentable() throws {
        let now: UInt = 1
        let clock1 = VectorClock(count: now, id: "clock-1")
        let clock2 = VectorClock(count: now)

        XCTAssertEqual(clock1.rawValue, "\(clock1.id):\(now)")
        XCTAssertEqual(clock2.rawValue, "\(clock2.id):\(now)")

        let clock11 = VectorClock(rawValue: clock1.rawValue)
        let clock22 = VectorClock(rawValue: clock2.rawValue)

        XCTAssertEqual(clock1, clock11)
        XCTAssertEqual(clock2, clock22)
    }

    func testVectorOrdering() throws {
        let a1 = VectorClock(id: "A")
        let b1 = VectorClock(id: "B")

        // neither clock has seen the other, so they're not <
        XCTAssertFalse(a1 < b1)
        XCTAssertFalse(b1 < a1)
        XCTAssertFalse(a1 > b1)
        XCTAssertFalse(b1 > a1)
        XCTAssertFalse(b1 == a1)

        // these clocks are neither before/after each other
        XCTAssertTrue(b1 <> a1)

        let a2 = a1.tick()

        XCTAssertFalse(a2 < b1)
        XCTAssertFalse(b1 < a2)
        XCTAssertFalse(a2 < a1)
        XCTAssertFalse(a1 > a2)
        XCTAssertTrue(a2 > a1)
        XCTAssertTrue(a1 < a2)

        let a3b1 = a2.tock(other: b1)

        XCTAssertFalse(a3b1 < b1)
        XCTAssertFalse(b1 < a3b1)

        let b2 = b1.tick()

        XCTAssertTrue(a3b1 < b2)

        let b2a1 = b1.tock(other: a1)

        XCTAssertFalse(a3b1 < b2a1)
        XCTAssertFalse(b2a1 < a3b1)

        // these clocks are neither before/after each other
        XCTAssertTrue(b2a1 <> a3b1)
    }
}

//
//  VectorClockTests.swift
//  
//
//  Created by Adam Wulf on 5/15/21.
//

import XCTest
@testable import Clocks

final class VectorClockTests: ClockTests {

    func testTick() throws {
        let clock1 = VectorClock(id: id1.rawValue)
        let clock2 = clock1.tick()

        XCTAssert(clock2.rawValue > clock1.rawValue)
        XCTAssert(clock2 > clock1)
    }

    func testReversingClock() throws {
        let clock1 = VectorClock(count: 1, id: id1.rawValue)
        let clock2 = VectorClock(count: 2, id: id2.rawValue)
        // use a previous timestamp, and ensure that our ticked clocks are after existing timestamps
        let clock31 = clock1.tock(other: clock2)
        let clock32 = clock1.tock(others: [clock1, clock2])
        let clock33 = clock1.tock(others: [clock2, clock1])

        XCTAssertEqual(clock1.rawValue.hexString, "000000000000000000000000000000010000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "000000000000000000000000000000020000000000000002")
        XCTAssertEqual(clock31.rawValue.hexString, "000000000000000000000000000000010000000000000002000000000000000000000000000000020000000000000002")
        XCTAssertEqual(clock32.rawValue.hexString, "000000000000000000000000000000010000000000000002000000000000000000000000000000020000000000000002")
        XCTAssertEqual(clock33.rawValue.hexString, "000000000000000000000000000000010000000000000002000000000000000000000000000000020000000000000002")
    }

    func testRawValue() throws {
        let now: UInt = 1

        let clock1 = VectorClock(count: now, id: id1.rawValue)
        let clock2 = VectorClock(rawValue: clock1.rawValue)

        XCTAssertEqual(clock1.rawValue.hexString, "000000000000000000000000000000010000000000000001")
        XCTAssertEqual(clock1, clock2)
    }

    func testIncCount() throws {
        let clock1 = VectorClock(count: 1, id: id1.rawValue)
        let clock2 = VectorClock(count: 1, id: id2.rawValue)
        let clock3 = clock1.tick()
        let clock4 = clock3.tock(other: clock2)
        let clock5 = clock2.tock(other: clock4)

        XCTAssertEqual(clock1.rawValue.hexString, "000000000000000000000000000000010000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "000000000000000000000000000000020000000000000001")
        XCTAssertEqual(clock3.rawValue.hexString, "000000000000000000000000000000010000000000000002")
        XCTAssertEqual(clock4.rawValue.hexString, "000000000000000000000000000000010000000000000003000000000000000000000000000000020000000000000001")
        XCTAssertEqual(clock5.rawValue.hexString, "000000000000000000000000000000020000000000000002000000000000000000000000000000010000000000000003")
    }

    func testRawRepresentable() throws {
        let now: UInt = 1
        let clock1 = VectorClock(count: now, id: id1.rawValue)
        let clock2 = VectorClock(count: now, id: id2.rawValue)

        XCTAssertEqual(clock1.rawValue.hexString, "000000000000000000000000000000010000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "000000000000000000000000000000020000000000000001")

        let clock11 = VectorClock(rawValue: clock1.rawValue)
        let clock22 = VectorClock(rawValue: clock2.rawValue)

        XCTAssertEqual(clock1, clock11)
        XCTAssertEqual(clock2, clock22)
    }

    func testVectorOrdering() throws {
        let a1 = VectorClock(id: id1.rawValue)
        let b1 = VectorClock(id: id2.rawValue)

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

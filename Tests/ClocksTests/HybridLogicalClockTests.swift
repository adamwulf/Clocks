//
//  HybridLogicalClockTests.swift
//  
//
//  Created by Adam Wulf on 5/14/21.
//

import XCTest
@testable import Clocks

final class HybridLogicalClockTests: ClockTests {

    func testTick() throws {
        let clock1 = HybridLogicalClock<SimpleIdentifier>()
        let clock2 = clock1.tick()

        XCTAssert(clock2.rawValue > clock1.rawValue)
        XCTAssert(clock2 > clock1)
    }

    func testReversingClock() throws {
        let now = HybridLogicalClock<SimpleIdentifier>(timestamp: 0)
        let clock1 = HybridLogicalClock<SimpleIdentifier>(timestamp: 1)
        let clock2 = HybridLogicalClock<SimpleIdentifier>(timestamp: 2)
        // use a previous timestamp, and ensure that our ticked clocks are after existing timestamps
        let clock31 = clock1.tock(now: now, other: clock2)
        let clock32 = clock1.tock(now: now, others: [clock1, clock2])
        let clock33 = clock1.tock(now: now, others: [clock2, clock1])

        XCTAssert(clock2.rawValue > clock1.rawValue)
        XCTAssert(clock31.rawValue > clock2.rawValue)
        XCTAssert(clock31.id.rawValue == clock1.id.rawValue)
        XCTAssert(clock32.rawValue > clock2.rawValue)
        XCTAssert(clock32.id.rawValue == clock1.id.rawValue)
        XCTAssert(clock33.rawValue > clock2.rawValue)
        XCTAssert(clock33.id.rawValue == clock1.id.rawValue)
        XCTAssertEqual(clock31, clock32)
        XCTAssertEqual(clock32, clock33)
    }

    func testRawValue() throws {
        let now: UInt64 = 1000

        let clock1 = HybridLogicalClock<SimpleIdentifier>(milliseconds: now, id: id1)
        let clock2 = HybridLogicalClock<SimpleIdentifier>(rawValue: clock1.rawValue)

        XCTAssertEqual(clock1.rawValue.hexString, "00000000000003e8000000000000000000000000000000000001")
        XCTAssertEqual(clock1, clock2)
    }

    func testIncCount() throws {
        let now1 = HybridLogicalClock<SimpleIdentifier>(timestamp: 1) // 1000ms
        let now2 = HybridLogicalClock<SimpleIdentifier>(timestamp: 2) // 2000ms

        let clock1 = HybridLogicalClock<SimpleIdentifier>(milliseconds: now1.milliseconds, id: id1)
        let clock2 = clock1.tick(now: now1)
        let clock3 = clock2.tick(now: now2)

        XCTAssertEqual(clock1.rawValue.hexString, "00000000000003e8000000000000000000000000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "00000000000003e8000100000000000000000000000000000001")
        XCTAssertEqual(clock3.rawValue.hexString, "00000000000007d0000000000000000000000000000000000001")
    }

    func testRawRepresentable() throws {
        let now: UInt64 = 1000
        let clock1 = HybridLogicalClock<SimpleIdentifier>(milliseconds: now, count: 0, id: id1)
        let clock2 = HybridLogicalClock<SimpleIdentifier>(milliseconds: now, count: 0, id: id2)

        XCTAssertEqual(clock1.rawValue.hexString, "00000000000003e8000000000000000000000000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "00000000000003e8000000000000000000000000000000000002")

        let clock11 = HybridLogicalClock<SimpleIdentifier>(rawValue: clock1.rawValue)
        let clock22 = HybridLogicalClock<SimpleIdentifier>(rawValue: clock2.rawValue)

        XCTAssertEqual(clock1, clock11)
        XCTAssertEqual(clock2, clock22)
    }

    func testDataRepresentable() throws {
        let now: UInt64 = 1000
        let clock1 = HybridLogicalClock<SimpleIdentifier>(milliseconds: now, count: 0, id: id1)
        let clock2 = HybridLogicalClock<SimpleIdentifier>(milliseconds: now, count: 0, id: id2)

        XCTAssertEqual(clock1.rawValue.hexString, "00000000000003e8000000000000000000000000000000000001")
        XCTAssertEqual(clock2.rawValue.hexString, "00000000000003e8000000000000000000000000000000000002")

        let clock11 = HybridLogicalClock<SimpleIdentifier>(rawValue: clock1.rawValue)
        let clock22 = HybridLogicalClock<SimpleIdentifier>(rawValue: clock2.rawValue)

        XCTAssertEqual(clock1, clock11)
        XCTAssertEqual(clock2, clock22)
    }

    func testSort() throws {
        var clocks = [
            HybridLogicalClock<SimpleIdentifier>(timestamp: 1, count: 0, id: id1),
            HybridLogicalClock<SimpleIdentifier>(timestamp: 4, count: 0, id: id1),
            HybridLogicalClock<SimpleIdentifier>(timestamp: 4, count: 1, id: id1),
            HybridLogicalClock<SimpleIdentifier>(timestamp: 6, count: 0, id: id1),
            HybridLogicalClock<SimpleIdentifier>(timestamp: 2, count: 0, id: id2),
            HybridLogicalClock<SimpleIdentifier>(timestamp: 3, count: 0, id: id2),
            HybridLogicalClock<SimpleIdentifier>(timestamp: 4, count: 0, id: id2),
            HybridLogicalClock<SimpleIdentifier>(timestamp: 5, count: 0, id: id2),
        ]
        clocks.sort()

        // ensure clocks sort by timestamp, then by count, then by id
        for i in 1..<clocks.count {
            let prev = clocks[i - 1]
            let this = clocks[i]

            XCTAssert(prev.milliseconds < this.milliseconds ||
                        (prev.milliseconds == this.milliseconds &&
                            (prev.count < this.count ||
                             (prev.count == this.count && prev.id.rawValue <= this.id.rawValue))))
        }
    }

    func testComparable() throws {
        let clock1 = HybridLogicalClock<SimpleIdentifier>(timestamp: 4, count: 2, id: id1)
        let clock2 = HybridLogicalClock<SimpleIdentifier>(timestamp: 4, count: 10, id: id2)

        XCTAssert(clock1 < clock2)
        XCTAssert(clock2 > clock1)
        XCTAssert(clock1 != clock2)

        let clock3 = HybridLogicalClock<SimpleIdentifier>(timestamp: 4, count: 2, id: id1)
        let clock4 = HybridLogicalClock<SimpleIdentifier>(timestamp: 20, count: 2, id: id2)

        XCTAssert(clock3 < clock4)
        XCTAssert(clock4 > clock3)
        XCTAssert(clock3 != clock4)
    }
}

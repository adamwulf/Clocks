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
struct LamportClock {
    let count: Int
    let id: String
    let others: [String: Int]

    init(count: Int = 0, id: String? = nil) {
        self.count = count
        self.id = id ?? String(String.uuid(prefix: "vec").prefix(12))
        self.others = [:]
    }
}

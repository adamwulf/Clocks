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
struct VectorClock {
    let count: Int
    let id: String

    init(count: Int = 0, id: String? = nil) {
        self.count = count
        self.id = id ?? String(String.uuid(prefix: "vec").prefix(12))
    }
}

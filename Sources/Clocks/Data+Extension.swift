//
//  File.swift
//  
//
//  Created by Adam Wulf on 10/20/21.
//

import Foundation

extension Data {
    static func random(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        for i in 0..<length {
            bytes[i] = UInt8.random(in: UInt8.min...UInt8.max)
        }
        return Data(bytes)
    }
    static func < (lhs: Data, rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { fatalError() }
        for i in 0..<lhs.count {
            if lhs[i] < rhs[i] {
                return true
            }
        }
        return false
    }
    static func > (lhs: Data, rhs: Data) -> Bool {
        return rhs < lhs
    }
    static func <= (lhs: Data, rhs: Data) -> Bool {
        return lhs < rhs || lhs == rhs
    }
    static func >= (lhs: Data, rhs: Data) -> Bool {
        return lhs > rhs || lhs == rhs
    }

    var hexString: String {
        return self.map { String(format: "%02hhx", $0) }.joined()
    }
}

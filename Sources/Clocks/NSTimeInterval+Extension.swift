//
//  File.swift
//  
//
//  Created by Adam Wulf on 10/20/21.
//

import Foundation

extension TimeInterval {
    init(milliseconds: UInt64) {
        self.init(Double(milliseconds) / 1000)
    }
    var milliseconds: UInt64 {
        return UInt64(self * 1000)
    }
}

//
//  File.swift
//  
//
//  Created by Adam Wulf on 5/15/21.
//

import Foundation

extension String {
    static func uuid(prefix: String = "") -> String {
        return prefix + (prefix.count > 0 ? "_" : "") + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}

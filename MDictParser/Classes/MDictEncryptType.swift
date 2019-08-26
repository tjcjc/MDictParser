//
//  MDictEncryptType.swift
//  MDictParser
//
//  Created by JasonTai on 2019/8/26.
//

import Foundation

enum MDictEncryptType: Int {
    case none = 0
    case reocrd = 1
    case keyInfo = 2
    
    init(_ string: String?) {
        if let str = string {
            if str.lowercased() == "yes" {
                self = .reocrd
            } else {
                let raw: Int! = Int(str)
                self.init(rawValue: raw)!
            }
        } else {
            self = .none
        }
    }
}

//
//  MDictParserTest.swift
//  MDictParser_Tests
//
//  Created by JasonTai on 2019/8/27.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import MDictParser

class MDictParserSpec: QuickSpec {
    var parser: MDictParser!
    override func spec() {
        beforeEach {
            self.parser = MDictParser(fileName: "oalecd8e")
        }
        
        describe("parse keys") {
            it("block") {
                expect(self.parser.parseKeyDataSize()) == [67, 109473, 1514, 787233]
            }
            
            it("meta data") {
//                self.parser.parseBlockMetaData()
            }
        }
    }
}

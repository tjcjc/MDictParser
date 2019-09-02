// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import MDictParser

class TableOfContentsSpec: QuickSpec {
    override func spec() {
        var mdictData: MDictData!
        describe("check header parser") {
            beforeEach {
                guard let path = Bundle.main.path(forResource: "oalecd8e", ofType: "mdx") else {
                    return
                }
                
                let rawData = try! Data(contentsOf: URL(fileURLWithPath: path))
                mdictData = MDictData(data: rawData, version: .v2, encoding: .utf8)
            }
            
            it("read int") {
                let headerCount: UInt32 = mdictData.readNum()
                expect(headerCount) == UInt32(2524)
            }
            

            it("scan header") {
                let length: UInt32 = mdictData.readNum()
                let headerData = mdictData.readSubRawData(length: Int(length))
                mdictData.checkAlder32(data: headerData, isLittle: true)
                let header = mdictData.scanHeader(headerData: headerData)
                expect(header["generatedbyengineversion"]).toNot(beNil())
                expect(header["encrypted"]).toNot(beNil())
            }
            
            it("parse header") {
                mdictData = MDictData(fileName: "oalecd8e")
                expect(mdictData.version) == MDictVersion.v2
            }
        }
        
        describe("check key parser") {
            beforeEach {
                mdictData = MDictData(fileName: "oalecd8e")
            }
            it("read key meta data") {
//                parser.parseHeader()
//                let data = parser.parseKeysMetaData(metaLength: UInt64(parser.version.keyHeaderLen))
//                expect(data) == [67, 109473, 1514, 787233]
            }
        }
        


        describe("these will fail") {

//            it("can do maths") {
//                expect(1) == 2
//            }
//
//            it("can read") {
//                expect("number") == "string"
//            }
//
//            it("will eventually fail") {
//                expect("time").toEventually( equal("done") )
//            }
//
            context("these will pass") {

                it("can do maths") {
                    expect(23) == 24
                }

                it("can read") {
                    expect("🐮") == "🐮"
                }

                it("will eventually pass") {
                    var time = "pasing"

                    DispatchQueue.main.async {
                        time = "done"
                    }

                    waitUntil { done in
                        Thread.sleep(forTimeInterval: 0.5)
                        expect(time) == "done"

                        done()
                    }
                }
            }
        }
    }
}

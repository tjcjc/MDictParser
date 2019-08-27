//
//  ViewController.swift
//  MDictParser
//
//  Created by tjcjc on 08/26/2019.
//  Copyright (c) 2019 tjcjc. All rights reserved.
//

import UIKit
import MDictParser

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var searchData: MDictSearchData = MDictParser(fileName: "LDOCE5++ V 2-15")!.getSearchData()
        searchData.searchWords(index: 12100)
        searchData.searchWords(index: 131000)
        searchData.searchWords(index: 15000)
        searchData.searchWords(index: 13310)
        searchData.searchWords(index: 84001)
//        print(UInt32(1).data())
//        let header = parser.readh
//        let header = parser.readPacked(checkIsLittleEndian: true)
//        print(parser.parseHeader(headerData: header))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


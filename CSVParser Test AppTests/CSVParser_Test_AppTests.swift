//
//  CSVParser_Test_AppTests.swift
//  CSVParser Test AppTests
//
//  Created by Chris on 16/01/2017.
//  Copyright © 2017 chrispysoft. All rights reserved.
//

import XCTest
@testable import CSVParser_Test_App

class CSVParser_Test_AppTests: XCTestCase {
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	
    func testTokens() {
		let input = ["1","2","3","4","5","6"]
		let data = input.joined().data(using: .utf8)!
		let csvdoc = CSVDocument(data: data)
		
		var idx = 0
		for line in csvdoc {
			XCTAssertEqual(line.first!, input[idx])
			idx += 1
		}
		
	}
	
}

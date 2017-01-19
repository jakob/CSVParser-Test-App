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
	
	
	
	func testTokenizerBasic() {
		let data = "1,2,3\n4,\"5\",6".data(using: .utf8)!
		let expectedTokens = [
			CSVToken(type: .Character, content: "1"),
			CSVToken(type: .Delimiter, content: ","),
			CSVToken(type: .Character, content: "2"),
			CSVToken(type: .Delimiter, content: ","),
			CSVToken(type: .Character, content: "3"),
			CSVToken(type: .LineSeparator, content: "\n"),
			CSVToken(type: .Character, content: "4"),
			CSVToken(type: .Delimiter, content: ","),
			CSVToken(type: .Quote, content: "\""),
			CSVToken(type: .Character, content: "5"),
			CSVToken(type: .Quote, content: "\""),
			CSVToken(type: .Delimiter, content: ","),
			CSVToken(type: .Character, content: "6"),
			CSVToken(type: .EndOfFile, content: "")
		]
		
		let tokenizer = UTF8DataTokenizer(data: data)
		
		var tokens = [CSVToken]()
		repeat {
			tokens.append(tokenizer.nextToken())
		} while tokens.last!.type != .EndOfFile
		
		XCTAssertEqual(tokens.count, expectedTokens.count, "Did not receive expected number of tokens")
		
		for i in tokens.indices where expectedTokens.indices.contains(i) {
			XCTAssertEqual(tokens[i].type, expectedTokens[i].type, "Token Type at index \(i) does not match")
			XCTAssertEqual(tokens[i].content, expectedTokens[i].content, "Token Content at index \(i) does not match")
			XCTAssertEqual(tokens[i], expectedTokens[i], "Token at index \(i) does not match")
		}
	}
	
	
	func testDocumentBasic() {
		let data = "1,2,3\n4,5,6".data(using: .utf8)!
		let expected = [
			["1","2","3"],
			["4","5","6"]
		]
		
		let csvdoc = CSVDocument(data: data)
		var actual = Array(csvdoc)
		
		XCTAssertEqual(actual.count, expected.count, "Did not receive expected number of lines")
		
		for i in actual.indices where expected.indices.contains(i) {
			XCTAssertEqual(actual[i].count, expected[i].count, "Line \(i) does not have expected length")
			XCTAssertEqual(actual[i], expected[i], "Line \(i) is not equal")
		}
		
	}
	
	
	func testDocumentQuoted() {
		let data = "1,\"2\",3\n4,\"5\"\n6,\"7\",\"8\",\"9\"".data(using: .utf8)!
		let expected = [
			["1","2","3"],
			["4","5"],
			["6","7","8","9"]
		]
		
		let csvdoc = CSVDocument(data: data)
		var actual = Array(csvdoc)
		
		XCTAssertEqual(actual.count, expected.count, "Did not receive expected number of lines")
		
		for i in actual.indices where expected.indices.contains(i) {
			XCTAssertEqual(actual[i].count, expected[i].count, "Line \(i) does not have expected length")
			XCTAssertEqual(actual[i], expected[i], "Line \(i) is not equal")
		}
		
	}
}

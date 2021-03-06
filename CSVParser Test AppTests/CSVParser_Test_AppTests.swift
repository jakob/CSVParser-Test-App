//
//  CSVParser_Test_AppTests.swift
//  CSVParser Test AppTests
//
//  Created by Chris on 16/01/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
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
	
	
	
	func testString() {
		let string = "1,\"2\",3\n4,\"5\"\n6,\"7\",\"8\",\"9\""
		let csvDoc = CSVDocument(string: string)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","2","3"],
			["4","5"],
			["6","7","8","9"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testData() {
		let data = "1,\"2\",3\n4,\"5\"\n6,\"7\",\"8\",\"9\"".data(using: .utf8)!
		let csvDoc = CSVDocument(data: data)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","2","3"],
			["4","5"],
			["6","7","8","9"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testUTF8() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/utf-8", withExtension: "csv")!
		
		let fileByteIterator = FileByteIterator(fileURL: fileURL)
		let codepointIterator = UTF8CodepointIterator(inputIterator: fileByteIterator)
		
		let expected = ["a","ä","®","€","𝄞","😀","🤓","🤢"]
		
		var i = 0
		while let char = codepointIterator.next(), expected.indices.contains(i) {
			while let warning = codepointIterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			
			XCTAssertEqual(String(char), expected[i], "Character \(i) is not equal")
			i += 1
		}
	}
	
	func testLatin1() {
		let testString = "aäu"
		let testData = testString.data(using: .isoLatin1)!
		
		let byteIterator = DataByteIterator(data: testData)
		let codepointIterator = UTF8CodepointIterator(inputIterator: byteIterator)
		
		let expected = ["a","ä","u"]
		
		var i = 0
		while let char = codepointIterator.next(), expected.indices.contains(i) {
			while let warning = codepointIterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			
			XCTAssertEqual(String(char), expected[i], "Character \(i) is not equal")
			i += 1
		}
		XCTAssertEqual(i,3)
	}

	
	func testBlankLines() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/blank-lines", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1"],
			["2"],
			[""],
			[""],
			["5"],
			["6"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testCommaSeparated() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/comma-separated", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["a","b","c"],
			["1","2","3"],
			["1.1","1.2","1.3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testCommaSeparatedQuote() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/comma-separated-quote", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["a","b","c"],
			["1","2","3"],
			["1,1","1,2","1,3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	
	func testDifferentLinesQuoted() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/different-lines-quoted", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","2","3"],
			["4","5"],
			[""],
			[""],
			["8","9","10"],
			["11"],
			["12"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testInvalidEncoding() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/invalid-encoding", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["text","ung�ltiger text","text"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testMissingBackslashAfterValue() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-backslash-afterValue", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","2","3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testMissingBackslashBeforeValue() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-backslash-beforeValue", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","2","3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testMissingQuoteAtEnd() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-quote-atEnd", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","2","3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testMissingValueForBackslashInQuote() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-value-for-backslash-inquote", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","\""]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testMissingValueForBackslash() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-value-for-backslash", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","\""]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testQuoteBackslashEscape() {
		var config = CSVConfig()
		config.delimiterCharacter = ";"
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/quote-backslash-escape", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["test\" test","test"],
			["1.2","1,3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testQuoteInUnquotedValue() {
		var config = CSVConfig()
		config.delimiterCharacter = ";"
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/quote-in-unquoted-value", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["iPhone5 Display","444"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testQuoteQuoteEscape() {
		var config = CSVConfig()
		config.delimiterCharacter = ";"
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/quote-quote-escape", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["test\"\" test","test"],
			["1.2","1,3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testSemicolonSeparated() {
		var config = CSVConfig()
		config.delimiterCharacter = ";"
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/semicolon-separated", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["a","b","c"],
			["1","2","3"],
			["1,1","1,2","1,3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
	
	func testTooManyQuotesAtEnd() {
		var config = CSVConfig()
		config.delimiterCharacter = ";"
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/tooMany-quotes-atEnd", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1",""]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() {
				print("WARNING: \(warning.text)")
			}
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		
		while let warning = iterator.nextWarning() {
			print("WARNING: \(warning.text)")
		}
	}
}

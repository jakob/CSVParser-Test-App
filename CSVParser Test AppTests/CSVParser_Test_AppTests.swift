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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
	}
	
	func testUTF8() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/utf-8", withExtension: "csv")!
		
		let fileByteIterator = FileByteIterator(fileURL: fileURL)
		let codepointIterator = UTF8CodepointIterator(inputIterator: fileByteIterator)
		
		let expected = ["a","ä","®","€","𝄞","😀","🤓","🤢"]
		
		var i = 0
		while let char = codepointIterator.next(), expected.indices.contains(i) {
			XCTAssertNil(codepointIterator.nextWarning())
			XCTAssertEqual(String(char), expected[i], "Character \(i) is not equal")
			i += 1
		}
		
		XCTAssertNil(codepointIterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertLessThan(idx, expected.count, "Received more lines than expected")
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertEqual(iterator.nextWarning()?.type, .invalidByteForUTF8Encoding)
		XCTAssertNil(iterator.nextWarning())
	}
	
	func testMissingBackslashAfterValue() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-backslash-afterValue", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		while let _ = iterator.next() {
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedCharacterAfterQuote)
		}
	}
	
	func testMissingBackslashBeforeValue() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-backslash-beforeValue", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		while let _ = iterator.next() {
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedCharacterAfterQuote)
		}
	}
	
	func testMissingQuoteAtEnd() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-quote-atEnd", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["1","2","3\n"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
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
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
	}
	
	func testEscapedQuote() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/escaped-quote", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["a","b","\"","c"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			XCTAssertNil(iterator.nextWarning())
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
	}
	
	func testPerformance() {
		self.measure {
			let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/semi-big-file", withExtension: "csv")!
			let csvDoc = CSVDocument(fileURL: fileURL)
			let iterator = csvDoc.makeIterator()
			
			while let _ = iterator.next() {}
			
			XCTAssertNil(iterator.nextWarning())
		}
	}
	
	func testPerformanceData() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/semi-big-file", withExtension: "csv")!
		self.measure {
			let csvData = try! Data(contentsOf: fileURL)
			let csvDoc = CSVDocument(data: csvData)
			let iterator = csvDoc.makeIterator()
			
			while let _ = iterator.next() {}
			
			XCTAssertNil(iterator.nextWarning())
		}
	}

	func testPerformanceString() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/semi-big-file", withExtension: "csv")!
		self.measure {
			let csvString = try! String(contentsOf: fileURL)
			let csvDoc = CSVDocument(string: csvString)
			let iterator = csvDoc.makeIterator()
			
			while let _ = iterator.next() {}
			
			XCTAssertNil(iterator.nextWarning())
		}
	}

	func testPerformanceIterators() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/semi-big-file", withExtension: "csv")!
		self.measure {
			let csvString = try! String(contentsOf: fileURL)
			let iterator = csvString.unicodeScalars.makeIterator()
			let config = CSVConfig()
			let tokenizer = TokenIterator(inputIterator: iterator, config: config)
			let parser = CSVParser(inputIterator: tokenizer, config: config)
			let simpleParser = SimpleParser(inputIterator: parser)
			while let _ = simpleParser.next() {}
			XCTAssertNil(simpleParser.nextWarning())
		}
	}
	
	/*
	func testPerformanceBigFile() {
		self.measure {
			let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/really-big-file", withExtension: "csv")!
			let csvDoc = CSVDocument(fileURL: fileURL)
			let iterator = csvDoc.makeIterator()
			
			while let _ = iterator.next() {}
			
			XCTAssertNil(iterator.nextWarning())
		}
	}
	*/
}

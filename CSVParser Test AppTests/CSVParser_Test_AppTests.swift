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
	
	func testLatin1() {
		let testString = "aäu€"
		var testData = testString.data(using: .windowsCP1252)!
		testData.append(0x81)
		
		let byteIterator = DataByteIterator(data: testData)
        let codepointIterator = Latin1CodepointIterator(inputIterator: byteIterator)
		
		let expected = ["a","ä","u","€","�"]
		
		var i = 0
		while let char = codepointIterator.next(), expected.indices.contains(i) {
			XCTAssertEqual(String(char), expected[i], "Character \(i) is not equal")
			i += 1
		}
		XCTAssertEqual(i,expected.count)
		XCTAssertEqual(codepointIterator.nextWarning()?.type, .invalidByteForEncoding)
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
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedQuote)
		}
	}
	
	func testMissingBackslashBeforeValue() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-backslash-beforeValue", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		while let _ = iterator.next() {
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedCharacter)
		}
	}
	
	func testMissingQuoteAtEnd() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/missing-quote-atEnd", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		while let _ = iterator.next() {
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedEOF)
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
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedEOF)
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
		
		while let _ = iterator.next() {
			XCTAssertEqual(iterator.nextWarning()?.type, .unrecognizedEscapedCharacter)
		}
	}
	
	func testQuoteBackslashQuote() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/quote-backslash-quote", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
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
	
	func testQuoteBackslashBackslash() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/quote-backslash-backslash", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["test\\ test","test"],
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
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/quote-in-unquoted-value", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["iPhone","5\" Display","444"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedQuote)
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
		XCTAssertNil(iterator.nextWarning())
	}
	
	func testQuoteQuoteEscape() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/quote-quote-escape", withExtension: "csv")!
		var config = CSVConfig()
		config.escapeCharacter = "\""
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		
		let expected = [
			["test\" test","test"],
			["1.2","1,3"]
		]
		
		var idx = 0
		while let elem = iterator.next() {
			XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
			XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
			idx += 1
		}
		
		XCTAssertEqual(idx, expected.count, "Did not receive expected number of lines")
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
	
	func testQuotesEscapes() {
		do {
			var config = CSVConfig()
			config.escapeCharacter = "\""
			let csvString = "1,\"2\"\"\",3"
			let csvDoc = CSVDocument(string: csvString, config: config)
			let iterator = csvDoc.makeIterator()
			
			XCTAssertEqual(iterator.next()!, ["1","2\"","3"])
			XCTAssertNil(iterator.nextWarning())
			XCTAssertNil(iterator.next())
		}
		do {
			var config = CSVConfig()
			config.escapeCharacter = "\\"
			let csvString = "1,\"2\\\"\",3"
			let csvDoc = CSVDocument(string: csvString, config: config)
			let iterator = csvDoc.makeIterator()
			
			XCTAssertEqual(iterator.next()!, ["1","2\"","3"])
			XCTAssertNil(iterator.nextWarning())
			XCTAssertNil(iterator.next())
		}
		do {
			var config = CSVConfig()
			config.escapeCharacter = "\\"
			let csvString = "1,\"2\"\"\",3"
			let csvDoc = CSVDocument(string: csvString, config: config)
			let iterator = csvDoc.makeIterator()
			while let _ = iterator.next() {}
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedQuote)
		}
		do {
			var config = CSVConfig()
			config.escapeCharacter = "\""
			let csvString = "1,\"2\\\"\",3"
			let csvDoc = CSVDocument(string: csvString, config: config)
			let iterator = csvDoc.makeIterator()
			while let _ = iterator.next() {}
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedEOF)
		}
	}
	
	func testTooManyQuotesAtEnd() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/tooMany-quotes-atEnd", withExtension: "csv")!
		let csvDoc = CSVDocument(fileURL: fileURL)
		let iterator = csvDoc.makeIterator()
		
		while let _ = iterator.next() {
			XCTAssertEqual(iterator.nextWarning()?.type, .unexpectedQuote)
		}
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
	
	func testIssuesSample() {
		let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/postico-issues", withExtension: "csv")!
		
		do {
			let csvDoc = CSVDocument(fileURL: fileURL)
			let iterator = csvDoc.makeIterator()
			while let elem = iterator.next() { _ = elem }
			XCTAssertNotNil(iterator.nextWarning())
		}

		do {
			var config = CSVConfig()
			config.escapeCharacter = "\""
			let csvDoc = CSVDocument(fileURL: fileURL, config: config)
			let iterator = csvDoc.makeIterator()
			
			var idx = 0
			while let elem = iterator.next() {
				XCTAssertNil(iterator.nextWarning(), "Warning in line \(idx)")
				XCTAssertEqual(elem.count, 7, "Line \(idx) does not have the correct length")
				idx += 1
			}
			XCTAssertNil(iterator.nextWarning())
		}

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
	
	// This test creates a temporary PostgreSQL table and loads a CSV file
	// Requires Postgres.app to be installed, and a PostgreSQL server must be running
	// This performance measurement is just for comparison; our code must be faster than this
	func testPerformanceIssuesPsql() {
		self.measure {
			let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/postico-issues", withExtension: "csv")!
			
			let psql = Process()
			psql.launchPath = "/Applications/Postgres.app/Contents/Versions/latest/bin/psql"
			psql.arguments = [
				"-c",
				"CREATE TEMP TABLE issues_temp ( number integer, created_at timestamp with time zone, username text, title text, body text, reaction_count integer, data jsonb );",
				"-c",
				"\\copy issues_temp from '\(fileURL.path)' with (format csv, header)"
			]
			psql.launch()
			psql.waitUntilExit()
			
			XCTAssertEqual(psql.terminationStatus, 0)
		}
	}

	// How long does it take us to parse a small CSV file?
	func testPerformanceIssues() {
		self.measure {
			let fileURL = Bundle(for: type(of: self)).url(forResource: "Reading Test Documents/postico-issues", withExtension: "csv")!
			var config = CSVConfig()
			config.escapeCharacter = "\""
			let csvDoc = CSVDocument(fileURL: fileURL, config: config)
			let iterator = csvDoc.makeIterator()
			
			var i = 0
			while let line = iterator.next() {
				XCTAssertEqual(line.count, 7, "Length of line \(i)")
				i += 1
			}
			XCTAssertEqual(i, 167, "Number of lines")
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
			let iterator = StringCodepointIterator(string: csvString)
			let config = CSVConfig()
			let tokenizer = TokenIterator(inputIterator: iterator, config: config)
			let parser = SlowCSVParser(inputIterator: tokenizer, config: config)
			let simpleParser = SimpleParser(inputIterator: parser)
			while let _ = simpleParser.next() {}
			XCTAssertNil(simpleParser.nextWarning())
		}
	}
	
}

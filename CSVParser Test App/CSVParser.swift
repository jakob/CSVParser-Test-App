//
//  CSVParser.swift
//  CSVParser Test App
//
//  Created by Chris on 16/01/2017.
//  Copyright © 2017 chrispysoft. All rights reserved.
//

import Foundation

struct CSVToken: Equatable {
	enum TokenType {
		case Delimiter
		case LineSeparator
		case Quote
		case Character
		case EndOfFile
	}
	var type: TokenType
	var content: String
	
	static func ==(lhs: CSVToken, rhs: CSVToken) -> Bool {
		return lhs.type == rhs.type && lhs.content == rhs.content
	}
}

enum CSVValue {
	case Quoted(value: String)
	case Unquoted(value: String)
	case None
	
	var value: String? {
		switch self {
		case let .Quoted(str), let .Unquoted(str):
			return str
		default:
			return nil
		}
	}
}

enum CSVWarning {
	case PlaceholderWarning(byteOffset: Int)
	case DefaultWarning
}




protocol CSVTokenizer {
	func nextToken() -> CSVToken
}

class UTF8DataTokenizer: CSVTokenizer {
	var string: String
	
	init(data: Data) {
		self.string = String(bytes: data, encoding: .utf8)!
	}
	
	func nextToken() -> CSVToken {
		if string.isEmpty {
			return CSVToken(type: .EndOfFile, content: "")
		}
		
		let char = string.remove(at: string.startIndex)
		let type: CSVToken.TokenType
		
		switch char {
		case ",":
			type = .Delimiter
		case "\n":
			type = .LineSeparator
		case "\"":
			type = .Quote
		default:
			type = .Character
			
		}
		
		let token = CSVToken(type: type, content: String(char))
		return token
	}
}


class ByteStreamReader {
	private var fileHandle: FileHandle?
	
	init?(fileURL: URL) {
		guard let fileHandle = FileHandle(forReadingAtPath: fileURL.path) else {
			return nil
		}
		self.fileHandle = fileHandle
	}
	
	deinit {
		fileHandle?.closeFile()
		fileHandle = nil
	}
	
	func nextByte() -> UInt8? {
		precondition(fileHandle != nil, "Attempt to read from closed file")
		
		guard let data = fileHandle?.readData(ofLength: 1), data.count > 0 else { return nil }
		
		var byte: UInt8 = 0
		data.copyBytes(to: &byte, count: MemoryLayout<UInt8>.size)
		return byte
	}
}


class CharacterStreamReader {
	private let byteStreamReader: ByteStreamReader
	
	typealias Warning = String
	
	init?(fileURL: URL) {
		guard let byteStreamReader = ByteStreamReader(fileURL: fileURL) else {
			return nil
		}
		self.byteStreamReader = byteStreamReader
	}
	
	func nextCharacter() -> (UnicodeScalar?, Warning?)? {
		guard let byte = byteStreamReader.nextByte() else {
			return nil
		}
		
		if (byte & 0b1000_0000) == 0 {
			// single byte
			return (UnicodeScalar(byte), nil)
		}
		else if (byte & 0b0100_0000) == 0 {
			// continuation byte
			return (nil, "Continuation byte at invalid position")
		}
		else if (byte & 0b0010_0000) == 0 {
			// first byte of two byte group
			let x = byte
			guard let y = byteStreamReader.nextByte() else {
				return (nil, "Expected second byte of group but found nil")
			}
			let res = (y & 0b111111) + ((x & 0b111111) << 6)
			return (UnicodeScalar(res), nil)
			
		}
		else if (byte & 0b0001_0000) == 0 {
			// first byte of three byte group
			let x = byte
			guard let y = byteStreamReader.nextByte() else {
				return (nil, "Expected second byte of group but found nil")
			}
			guard let z = byteStreamReader.nextByte() else {
				return (nil, "Expected third byte of group but found nil")
			}
			let res = (z & 0b111111) + ((y & 0b111111) << 6) + ((x & 0b1111) << 3)
			return (UnicodeScalar(res), nil)
			
		}
		
		return nil
		
	}
}



class StreamTokenizer: CSVTokenizer {
	var string: String
	
	init(data: Data) {
		self.string = String(bytes: data, encoding: .utf8)!
	}
	/*
	func nextByte() -> Int8 {
		
	}
	
	func nextCharacter() -> UnicodeScalar {
		
	}
	*/
	func nextToken() -> CSVToken {
		if string.isEmpty {
			return CSVToken(type: .EndOfFile, content: "")
		}
		
		let char = string.remove(at: string.startIndex)
		let type: CSVToken.TokenType
		
		switch char {
		case ",":
			type = .Delimiter
		case "\n":
			type = .LineSeparator
		case "\"":
			type = .Quote
		default:
			type = .Character
			
		}
		
		let token = CSVToken(type: type, content: String(char))
		return token
	}
}



class CSVParser: Sequence, IteratorProtocol {
	
	enum Mode {
		case beforeQuote
		case insideQuote
		case afterQuote
	}
	
	typealias CSVLine = ([CSVValue],[CSVWarning])
	
	let tokenizer: CSVTokenizer
	
	
	init(tokenizer: CSVTokenizer) {
		self.tokenizer = tokenizer
	}
	
	func next() -> CSVLine? {
		var values = [CSVValue]()
		var warnings = [CSVWarning]()
		var currValue = ""
		var mode = Mode.beforeQuote
		
		func appendValue() {
			let val = (mode == .beforeQuote) ? CSVValue.Unquoted(value: currValue) : CSVValue.Quoted(value: currValue)
			values.append(val)
			currValue = ""
		}
		func appendWarning() {
			let warning = CSVWarning.DefaultWarning
			warnings.append(warning)
		}

		var token = tokenizer.nextToken()
		if token.type == .EndOfFile {
			return nil
		}
		
		while true {
			
			switch (mode, token.type) {
			
			case (.afterQuote, .Quote):
				currValue += token.content
				mode = .insideQuote
				
			case (.afterQuote, .Character):
				currValue += token.content
				print("WARNING: mode=\(mode), type=\(token.type)")
				appendWarning()
				
			case (_, .Character):
				currValue += token.content
				
			case (.insideQuote, .Quote):
				mode = .afterQuote
				
			case (.insideQuote, .EndOfFile):
				appendWarning()
				appendValue()
				return (values, warnings)

			case (.insideQuote, _):
				currValue += token.content
				
			case (_, .Delimiter):
				appendValue()
				mode = .beforeQuote
				
			case (.beforeQuote, .Quote):
				if !currValue.isEmpty { appendWarning() }
				mode = .insideQuote
				
			case (_, .LineSeparator), (_, .EndOfFile):
				appendValue()
				return (values, warnings)
				
			default:
				fatalError("Impossible case: mode=\(mode), tokenType=\(token.type)")
			}
			
			token = tokenizer.nextToken()
		}
		
		
	}
	
}

struct SimpleParser: Sequence, IteratorProtocol {
	let parser: CSVParser
	func next() -> [String]? {
		guard let (values, _) = parser.next() else { return nil }
		return values.map { $0.value ?? "" }
	}
}



struct CSVConfig {
	var encoding = String.Encoding.utf8
	var columnSeparator = ","
	var quoteCharacter = "\""
	var escapeCharacter = "\""
	var decimalMark = "."
	var firstRowAsHeader = false
	
	var description: String {
		return "encoding: '\(encoding)', separator: '\(columnSeparator)', quote: '\(quoteCharacter)', escape: '\(escapeCharacter)', decimal: '\(decimalMark)', firstAsHeader: \(firstRowAsHeader)"
	}
}



class CSVDocument: Sequence {
	private let data: Data
	private let config: CSVConfig
	
	init(data: Data, config: CSVConfig = CSVConfig()) {
		self.data = data
		self.config = config
	}
	
	var csvParser: CSVParser {
		let tok = UTF8DataTokenizer(data: data)
		let parser = CSVParser(tokenizer: tok)
		return parser
	}
	
	var simpleParser: SimpleParser {
		return SimpleParser(parser: csvParser)
	}
	
	func makeIterator() -> SimpleParser {
		return simpleParser
	}
}

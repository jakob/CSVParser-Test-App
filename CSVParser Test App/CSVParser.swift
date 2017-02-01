//
//  CSVParser.swift
//  CSVParser Test App
//
//  Created by Chris on 16/01/2017.
//  Copyright © 2017 chrispysoft. All rights reserved.
//

import Foundation

struct CSVConfig {
	var encoding = String.Encoding.utf8
	var delimiterCharacter: Character = ","
	var quoteCharacter: Character = "\""
	var escapeCharacter: Character = "\\"
	var decimalCharacter: Character = "."
	var newlineCharacter: Character = "\n"
	var firstRowAsHeader = false
	
	var description: String {
		return "encoding: '\(encoding)', delimiter: '\(delimiterCharacter)', quote: '\(quoteCharacter)', escape: '\(escapeCharacter)', decimal: '\(decimalCharacter)', firstRowAsHeader: \(firstRowAsHeader)"
	}
}

struct CSVToken: Equatable {
	enum TokenType {
		case delimiter
		case lineSeparator
		case quote
		case character
		case endOfFile
	}
	var type: TokenType
	var content: String
	
	static func ==(lhs: CSVToken, rhs: CSVToken) -> Bool {
		return lhs.type == rhs.type && lhs.content == rhs.content
	}
}

enum CSVValue {
	case quoted(value: String)
	case unquoted(value: String)
	case none
	
	var value: String? {
		switch self {
		case let .quoted(str), let .unquoted(str):
			return str
		default:
			return nil
		}
	}
}

enum CSVWarning {
	case placeholderWarning(byteOffset: Int)
	case defaultWarning
}



/*
	DOCUMENT
*/
class CSVDocument: Sequence {
	private let fileURL: URL?
	private let sourceData: Data?
	private let config: CSVConfig
	
	init(fileURL: URL, config: CSVConfig = CSVConfig()) {
		self.fileURL = fileURL
		self.sourceData = nil
		self.config = config
	}
	
	init(data: Data, config: CSVConfig = CSVConfig()) {
		self.fileURL = nil
		self.sourceData = data
		self.config = config
	}

	
	var csvParser: CSVParser {
		let byteReader: ByteReader
		if let url = fileURL {
			byteReader = ByteStreamReader(fileURL: url)
		}
		else if let data = sourceData {
			byteReader = ByteDataReader(data: data)
		}
		else {
			fatalError("This should be unreachable")
		}
		
		let characterStreamReader: CharacterStreamReader
		if config.encoding == .utf8 {
			characterStreamReader = CharacterStreamReader(byteReader: byteReader)
		} else {
			fatalError("Unsupported Character Encoding")
		}
		
		let tokenizer = StreamTokenizer(characterStreamReader: characterStreamReader, config: config)
		let parser = CSVParser(tokenizer: tokenizer)
		return parser
	}
	
	var simpleParser: SimpleParser {
		return SimpleParser(parser: csvParser)
	}
	
	func makeIterator() -> SimpleParser {
		return simpleParser
	}
}



/*
	PARSER
*/
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
			let val = (mode == .beforeQuote) ? CSVValue.unquoted(value: currValue) : CSVValue.quoted(value: currValue)
			values.append(val)
			currValue = ""
		}
		func appendWarning() {
			let warning = CSVWarning.defaultWarning
			warnings.append(warning)
		}
		
		var token = tokenizer.nextToken()
		if token.type == .endOfFile {
			return nil
		}
		
		while true {
			
			switch (mode, token.type) {
				
			case (.afterQuote, .quote):
				currValue += token.content
				mode = .insideQuote
				
			case (.afterQuote, .character):
				currValue += token.content
				print("WARNING: mode=\(mode), type=\(token.type)")
				appendWarning()
				
			case (_, .character):
				currValue += token.content
				
			case (.insideQuote, .quote):
				mode = .afterQuote
				
			case (.insideQuote, .endOfFile):
				appendWarning()
				appendValue()
				return (values, warnings)
				
			case (.insideQuote, _):
				currValue += token.content
				
			case (_, .delimiter):
				appendValue()
				mode = .beforeQuote
				
			case (.beforeQuote, .quote):
				if !currValue.isEmpty { appendWarning() }
				mode = .insideQuote
				
			case (_, .lineSeparator), (_, .endOfFile):
				appendValue()
				return (values, warnings)
				
			default:
				fatalError("Impossible case: mode=\(mode), tokenType=\(token.type)")
			}
			
			token = tokenizer.nextToken()
		}
	}
}

class SimpleParser: Sequence, IteratorProtocol {
	let parser: CSVParser
	
	init(parser: CSVParser) {
		self.parser = parser
	}
	
	func next() -> [String]? {
		guard let (values, _) = parser.next() else { return nil }
		return values.map { $0.value ?? "" }
	}
}



/*
	TOKENIZER
*/
protocol CSVTokenizer {
	func nextToken() -> CSVToken
}

class UTF8DataTokenizer: CSVTokenizer {
	var string: String
	var config: CSVConfig
	
	init(data: Data, config: CSVConfig) {
		self.string = String(bytes: data, encoding: .utf8)!
		self.config = config
	}
	
	func nextToken() -> CSVToken {
		if string.isEmpty {
			return CSVToken(type: .endOfFile, content: "")
		}
		
		let char = string.remove(at: string.startIndex)
		let type: CSVToken.TokenType
		
		switch char {
		case config.delimiterCharacter:
			type = .delimiter
		case config.newlineCharacter:
			type = .lineSeparator
		case config.quoteCharacter:
			type = .quote
		default:
			type = .character
		}
		
		let token = CSVToken(type: type, content: String(char))
		return token
	}
}

class StreamTokenizer: CSVTokenizer {
	var characterStreamReader: CharacterStreamReader
	var config: CSVConfig
	
	init(characterStreamReader: CharacterStreamReader, config: CSVConfig) {
		self.characterStreamReader = characterStreamReader
		self.config = config
	}
	
	func nextToken() -> CSVToken {
		guard let result = characterStreamReader.nextCharacter() else {
			return CSVToken(type: .endOfFile, content: "")
		}
		guard let char = result.char else {
			return CSVToken(type: .endOfFile, content: "")
		}
		
		let type: CSVToken.TokenType
		
		switch Character(char) {
		case config.delimiterCharacter:
			type = .delimiter
		case config.newlineCharacter:
			type = .lineSeparator
		case config.quoteCharacter:
			type = .quote
		default:
			type = .character
		}
		
		let token = CSVToken(type: type, content: String(char))
		return token
	}
}



/*
	CHARACTER READER
*/
class CharacterStreamReader {
	typealias CharacterStreamResult = (char: UnicodeScalar?, warning: String?)
	
	static let ItemReplacementChar = UnicodeScalar(0xFFFD)
	
	private let byteReader: ByteReader
	
	init(byteReader: ByteReader) {
		self.byteReader = byteReader
	}
	
	private var returnedByte: UInt8?
	
	private func nextByte() -> UInt8? {
		if let b = returnedByte {
			returnedByte = nil
			return b
		}
		return byteReader.nextByte()
	}
	
	private func returnByte(_ byte: UInt8) {
		if returnedByte != nil {
			fatalError("Returned byte is already set")
		}
		returnedByte = byte
	}
	
	func nextCharacter() -> CharacterStreamResult? {
		guard let byte = nextByte() else {
			return nil
		}
		
		// single byte
		if (byte & 0b1000_0000) == 0 {
			return (UnicodeScalar(byte), nil)
		}
		
		// continuation byte
		else if (byte & 0b0100_0000) == 0 {
			return (CharacterStreamReader.ItemReplacementChar, "Continuation byte at invalid position")
		}
		
		// first byte of two byte group
		else if (byte & 0b0010_0000) == 0 {
			let a = byte
			guard let b = nextByte() else {
				return (CharacterStreamReader.ItemReplacementChar, "Expected second byte of group but found nil")
			}
			
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				// put byte back
				returnByte(b)
				return (CharacterStreamReader.ItemReplacementChar, "Expected continuation byte")
			}
			
			let res = UInt32(b & 0b111111) + (UInt32(a & 0b11111) << 6)
			return (UnicodeScalar(res), nil)
		}
		
		// first byte of three byte group
		else if (byte & 0b0001_0000) == 0 {
			
			let a = byte
			guard let b = nextByte() else {
				return (nil, "Expected second byte of group but found nil")
			}
			
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				// put byte back
				returnByte(b)
				return (CharacterStreamReader.ItemReplacementChar, "Expected continuation byte")
			}
			
			guard let c = nextByte() else {
				return (nil, "Expected third byte of group but found nil")
			}
			
			guard (c & 0b1100_0000) == 0b1000_0000 else {
				// put byte back
				returnByte(c)
				return (CharacterStreamReader.ItemReplacementChar, "Expected continuation byte")
			}
			
			let res = UInt32(c & 0b111111) + (UInt32(b & 0b111111) << 6) + (UInt32(a & 0b1111) << 12)
			return (UnicodeScalar(res), nil)
		}
		
		// first byte of four byte group
		else if (byte & 0b0000_1000) == 0 {
			
			let a = byte
			guard let b = nextByte() else {
				return (nil, "Expected second byte of group but found nil")
			}
			guard let c = nextByte() else {
				return (nil, "Expected third byte of group but found nil")
			}
			guard let d = nextByte() else {
				return (nil, "Expected fourth byte of group but found nil")
			}
			
			let res = UInt32(d & 0b111111) + (UInt32(c & 0b111111) << 6) + (UInt32(b & 0b111111) << 12) + (UInt32(a & 0b1111) << 18)
			return (UnicodeScalar(res), nil)
			
		}
		
		// invalid byte
		else {
			return (CharacterStreamReader.ItemReplacementChar, "Invalid byte")
		}
		
	}
}



/*
	BYTE READER
*/
protocol ByteReader {
	func nextByte() -> UInt8?
}

class ByteStreamReader: ByteReader {
	private let fileURL: URL
	private var fileHandle: FileHandle?
	
	init(fileURL: URL) {
		self.fileURL = fileURL
	}
	
	deinit {
		fileHandle?.closeFile()
		fileHandle = nil
	}
	
	func nextByte() -> UInt8? {
		if fileHandle == nil {
			fileHandle = FileHandle(forReadingAtPath: fileURL.path)
		}
		
		guard let data = fileHandle?.readData(ofLength: 1), data.count > 0 else { return nil }
		
		var byte: UInt8 = 0
		data.copyBytes(to: &byte, count: MemoryLayout<UInt8>.size)
		return byte
	}
}

class ByteDataReader: ByteReader {
	private var data: Data
	private var index: Int = 0
	
	init(data: Data) {
		self.data = data
	}
	
	func nextByte() -> UInt8? {
		if index < data.count {
			let byte = data[index]
			index += 1
			return byte
		}
		return nil
		
	}
}

//
//  CSVParser.swift
//  CSVParser Test App
//
//  Created by Chris on 02/02/2017.
//  Copyright © 2017 chrispysoft. All rights reserved.
//

import Foundation

/*
Types
*/

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

struct CSVValue {
	var value: String?
	var quoted: Bool
	
	init(_ value: String, quoted: Bool = false) {
		self.value = value
		self.quoted = quoted
	}
}

struct CSVWarning {
	let text: String
}

enum CSVParsingMode {
	case beforeQuote
	case insideQuote
	case afterQuote
}



/*
WarningProducer / Iterators
*/

protocol WarningProducer {
	mutating func nextWarning() -> CSVWarning?
}


class IteratorWithWarnings<Element>: IteratorProtocol, WarningProducer {
	var warnings = [CSVWarning]()
	
	func next() -> Element? {
		fatalError("This method is abstract")
	}
	
	func nextWarning() -> CSVWarning? {
		fatalError("This method is abstract")
	}
}

class ConcreteIteratorWithWarnings<I: IteratorProtocol>: IteratorWithWarnings<I.Element> {
	var iterator: I
	
	init(_ iterator: I) {
		self.iterator = iterator
	}
	
	override func next() -> I.Element? {
		return iterator.next()
	}
	
	override func nextWarning() -> CSVWarning? {
		if var warningProducer = iterator as? WarningProducer {
			return warningProducer.nextWarning()
		}
		return nil
	}
}



/*
Document
*/

class CSVDocument: Sequence {
	private let fileURL: URL?
	private let sourceData: Data?
	private let sourceString: String?
	private let config: CSVConfig
	var warnings = [CSVWarning]()
	
	init(fileURL: URL, config: CSVConfig = CSVConfig()) {
		self.fileURL = fileURL
		self.sourceData = nil
		self.sourceString = nil
		self.config = config
	}
	
	init(data: Data, config: CSVConfig = CSVConfig()) {
		self.fileURL = nil
		self.sourceData = data
		self.sourceString = nil
		self.config = config
	}
	
	init(string: String, config: CSVConfig = CSVConfig()) {
		self.fileURL = nil
		self.sourceData = nil
		self.sourceString = string
		self.config = config
	}

	
	func makeIterator() -> IteratorWithWarnings<[String]> {
		return ConcreteIteratorWithWarnings(SimpleParser(parser: makeCSVValueIterator()))
	}
	
	func makeCSVValueIterator() -> IteratorWithWarnings<[CSVValue]> {
		let codepointIterator: IteratorWithWarnings<UnicodeScalar>
		
		if let str = sourceString {
			codepointIterator = ConcreteIteratorWithWarnings(str.unicodeScalars.makeIterator())
		}
		else {
			let byteIterator: IteratorWithWarnings<UInt8>
			if let url = fileURL {
				byteIterator = ConcreteIteratorWithWarnings(FileByteIterator(fileURL: url))
			}
			else if let data = sourceData {
				byteIterator = ConcreteIteratorWithWarnings(DataByteIterator(data: data))
			}
			else {
				fatalError("This should be unreachable")
			}
			if config.encoding == .utf8 {
				codepointIterator = ConcreteIteratorWithWarnings(UTF8CodepointIterator(byteIterator: byteIterator))
			} else {
				fatalError("Unsupported Character Encoding")
			}

		}
		
		let tokenizer = TokenIterator(inputIterator: codepointIterator, config: config)
		let parser = CSVParser(inputIterator: tokenizer, config: config)
		return ConcreteIteratorWithWarnings(parser)
	}
	
}



/*
Parsers
*/

class CSVParser<InputIterator : IteratorProtocol> : Sequence, IteratorProtocol, WarningProducer where InputIterator.Element == CSVToken {
	private var inputIterator: InputIterator
	private var config: CSVConfig
	var warnings = [CSVWarning]()
	
	init(inputIterator: InputIterator, config: CSVConfig) {
		self.inputIterator = inputIterator
		self.config = config
	}
	
	func next() -> [CSVValue]? {
		var values = [CSVValue]()
		var warnings = [CSVWarning]()
		var currValue = ""
		var mode = CSVParsingMode.beforeQuote
		
		func appendValue() {
			let quoted = (mode == .beforeQuote) ? false : true
			let val = CSVValue(currValue, quoted: quoted)
			values.append(val)
			currValue = ""
		}
		func appendWarning(_ text: String) {
			let warning = CSVWarning(text: text)
			warnings.append(warning)
		}
		
		guard var token = inputIterator.next(), token.type != .endOfFile else {
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
				appendWarning("")
				
			case (_, .character):
				currValue += token.content
				
			case (.insideQuote, .quote):
				mode = .afterQuote
				
			case (.insideQuote, .endOfFile):
				appendWarning("")
				appendValue()
				return values
				
			case (.insideQuote, _):
				currValue += token.content
				
			case (_, .delimiter):
				appendValue()
				mode = .beforeQuote
				
			case (.beforeQuote, .quote):
				if !currValue.isEmpty { appendWarning("") }
				mode = .insideQuote
				
			case (_, .lineSeparator), (_, .endOfFile):
				appendValue()
				return values
				
			default:
				fatalError("Impossible case: mode=\(mode), tokenType=\(token.type)")
			}
			
			guard let nextToken = inputIterator.next() else {
				return nil
			}
			token = nextToken
		}
	}
	
	func nextWarning() -> CSVWarning? {
		return warnings.isEmpty ? nil : warnings.removeFirst()
	}
}

class SimpleParser<InputIterator: IteratorProtocol & WarningProducer> : Sequence, IteratorProtocol, WarningProducer where InputIterator.Element == [CSVValue] {
	var parser: InputIterator
	
	init(parser: InputIterator) {
		self.parser = parser
	}
	
	func next() -> [String]? {
		guard let values = parser.next() else { return nil }
		return values.map { $0.value ?? "" }
	}
	
	func nextWarning() -> CSVWarning? {
		return parser.nextWarning()
	}
}



/*
TokenIterators
*/

class TokenIterator<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer where InputIterator.Element == UnicodeScalar {
	private var inputIterator: InputIterator
	private var config: CSVConfig
	
	init(inputIterator: InputIterator, config: CSVConfig) {
		self.inputIterator = inputIterator
		self.config = config
	}
	
	func next() -> CSVToken? {
		guard let char = inputIterator.next() else {
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
	
	func nextWarning() -> CSVWarning? {
		if var warningProducer = inputIterator as? WarningProducer {
			return warningProducer.nextWarning()
		}
		return nil
	}
}



/*
Codepoint Iterators
*/

let ItemReplacementChar = UnicodeScalar(0xFFFD)

class UTF8CodepointIterator<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer where InputIterator.Element == UInt8 {
	private var byteIterator: InputIterator
	var warnings = [CSVWarning]()
	
	init(byteIterator: InputIterator) {
		self.byteIterator = byteIterator
	}
	
	private var returnedByte: UInt8?
	
	private func nextByte() -> UInt8? {
		if let b = returnedByte {
			returnedByte = nil
			return b
		}
		let nextByte = byteIterator.next()
		if var warningProducer = byteIterator as? WarningProducer {
			while let w = warningProducer.nextWarning() {
				warnings.append(w)
			}
		}
		return nextByte
	}
	
	private func returnByte(_ byte: UInt8) {
		if returnedByte != nil {
			fatalError("Returned byte is already set")
		}
		returnedByte = byte
	}
	
	
	func nextWarning() -> CSVWarning? {
		return warnings.isEmpty ? nil : warnings.removeFirst()
	}
	
	func next() -> UnicodeScalar? {
		guard let byte = nextByte() else {
			return nil
		}
		
		// single byte
		if (byte & 0b1000_0000) == 0 {
			return UnicodeScalar(byte)
		}
		
		// continuation byte
		else if (byte & 0b0100_0000) == 0 {
			warnings.append(CSVWarning(text:"Continuation byte at invalid position"))
			return ItemReplacementChar
		}
		
		// first byte of two byte group
		else if (byte & 0b0010_0000) == 0 {
			let a = byte
			guard let b = nextByte() else {
				warnings.append(CSVWarning(text:"Expected second byte of group but found nil"))
				return ItemReplacementChar
			}
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				returnByte(b)
				warnings.append(CSVWarning(text: "Expected continuation byte"))
				return ItemReplacementChar
			}
			
			let res = UInt32(b & 0b111111) + (UInt32(a & 0b11111) << 6)
			return UnicodeScalar(res)
		}
		
		// first byte of three byte group
		else if (byte & 0b0001_0000) == 0 {
			
			let a = byte
			guard let b = nextByte() else {
				warnings.append(CSVWarning(text: "Expected second byte of group but found nil"))
				return ItemReplacementChar
			}
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				returnByte(b)
				warnings.append(CSVWarning(text: "Expected continuation byte"))
				return ItemReplacementChar
			}
			guard let c = nextByte() else {
				warnings.append(CSVWarning(text: "Expected third byte of group but found nil"))
				return ItemReplacementChar
			}
			guard (c & 0b1100_0000) == 0b1000_0000 else {
				returnByte(c)
				warnings.append(CSVWarning(text: "Expected continuation byte"))
				return ItemReplacementChar
			}
			
			let res = UInt32(c & 0b111111) + (UInt32(b & 0b111111) << 6) + (UInt32(a & 0b1111) << 12)
			return UnicodeScalar(res)
		}
		
		// first byte of four byte group
		else if (byte & 0b0000_1000) == 0 {
			
			let a = byte
			guard let b = nextByte() else {
				warnings.append(CSVWarning(text: "Expected second byte of group but found nil"))
				return ItemReplacementChar
			}
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				returnByte(b)
				warnings.append(CSVWarning(text: "Expected continuation byte"))
				return ItemReplacementChar
			}
			guard let c = nextByte() else {
				warnings.append(CSVWarning(text: "Expected third byte of group but found nil"))
				return ItemReplacementChar
			}
			guard (c & 0b1100_0000) == 0b1000_0000 else {
				returnByte(c)
				warnings.append(CSVWarning(text: "Expected continuation byte"))
				return ItemReplacementChar
			}
			guard let d = nextByte() else {
				warnings.append(CSVWarning(text: "Expected fourth byte of group but found nil"))
				return ItemReplacementChar
			}
			guard (d & 0b1100_0000) == 0b1000_0000 else {
				returnByte(d)
				warnings.append(CSVWarning(text: "Expected continuation byte"))
				return ItemReplacementChar
			}
			
			let res = UInt32(d & 0b111111) + (UInt32(c & 0b111111) << 6) + (UInt32(b & 0b111111) << 12) + (UInt32(a & 0b1111) << 18)
			return UnicodeScalar(res)
			
		}
		
		// invalid byte
		else {
			warnings.append(CSVWarning(text: "Invalid byte"))
			return ItemReplacementChar
		}
	}
}



/*
Byte Iterators
*/

class FileByteIterator: Sequence, IteratorProtocol, WarningProducer {
	internal var warnings = [CSVWarning]()

	private let fileURL: URL
	private var fileHandle: FileHandle?
	
	init(fileURL: URL) {
		self.fileURL = fileURL
	}
	
	deinit {
		fileHandle?.closeFile()
		fileHandle = nil
	}
	
	func next() -> UInt8? {
		if fileHandle == nil {
			fileHandle = FileHandle(forReadingAtPath: fileURL.path)
			if fileHandle == nil {
				warnings.append(CSVWarning(text: "File \(fileURL.lastPathComponent) could not be opened"))
			}
		}
		
		guard let data = fileHandle?.readData(ofLength: 1), data.count > 0 else { return nil }
		
		var byte: UInt8 = 0
		data.copyBytes(to: &byte, count: MemoryLayout<UInt8>.size)
		return byte
	}
	
	func nextWarning() -> CSVWarning? {
		return warnings.isEmpty ? nil : warnings.removeFirst()
	}
}

class DataByteIterator: IteratorWithWarnings<UInt8> { //Sequence, IteratorProtocol, WarningProducer
	private var data: Data
	private var index: Int = 0
	
	init(data: Data) {
		self.data = data
	}
	
	override func next() -> UInt8? {
		if index < data.count {
			let byte = data[index]
			index += 1
			return byte
		}
		return nil
	}
}

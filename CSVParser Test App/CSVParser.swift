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
		switch (self) {
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



class CSVParser: Sequence, IteratorProtocol {
	
	enum Mode {
		case Bare
		case InsideQuote
		case AfterQuote
	}
	
	let tokenizer: CSVTokenizer
	
	
	init(tokenizer: CSVTokenizer) {
		self.tokenizer = tokenizer
	}
	
	func next() -> ([CSVValue],[CSVWarning])? {
		var values = [CSVValue]()
		var warnings = [CSVWarning]()
		var currValue = ""
		var mode = Mode.Bare
		
		func appendValue() {
			let val = (mode == .Bare) ? CSVValue.Unquoted(value: currValue) : CSVValue.Quoted(value: currValue)
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
			
			case (.AfterQuote, .Character):
				print("WARNING: mode=\(mode), type=\(token.type)")
				appendWarning()
				
			case (_, .Character):
				currValue += token.content
				
			case (.InsideQuote, .Quote):
				mode = .AfterQuote
				
			case (.InsideQuote, _):
				currValue += token.content
				
			case (_, .Delimiter):
				appendValue()
				mode = .Bare
				
			case (.Bare, .Quote):
				mode = .InsideQuote
				break
				
			case (.Bare, .LineSeparator), (.Bare, .EndOfFile):
				appendValue()
				return (values, warnings)
				
			case (.AfterQuote, .LineSeparator), (.AfterQuote, .EndOfFile):
				appendValue()
				return (values, warnings)
				
			default:
				print("DEFAULT CASE: mode=\(mode), type=\(token.type)")
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
	
}



class CSVDocument: Sequence {
	let data: Data
	var config = CSVConfig()
	
	init(data: Data) {
		self.data = data
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

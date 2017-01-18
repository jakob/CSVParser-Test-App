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
}




protocol CSVTokenizer {
	func nextToken() -> CSVToken?
}

class UTF8DataTokenizer: CSVTokenizer {
	var string: String
	init(data: Data) {
		self.string = String(bytes: data, encoding: .utf8)!
	}
	func nextToken() -> CSVToken? {
		if string.isEmpty {
			return nil
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
	
	let tokenizer: CSVTokenizer
	
	init(tokenizer: CSVTokenizer) {
		self.tokenizer = tokenizer
	}
	
	func next() -> ([CSVValue],[CSVWarning])? {
		var values = [CSVValue]()
		var currValue = ""
		
		guard var token = tokenizer.nextToken() else {
			return nil
		}
		
		while true {
			
			switch token.type {
			case .Character, .Quote:
				currValue += token.content
			case .Delimiter:
				let val = CSVValue.Unquoted(value: currValue)
				values.append(val)
				currValue = ""
			case .LineSeparator:
				let val = CSVValue.Unquoted(value: currValue)
				values.append(val)
				return (values, [])
			}
			
			guard let next = tokenizer.nextToken() else {
				let val = CSVValue.Unquoted(value: currValue)
				values.append(val)
				return (values, [])
			}
			
			token = next
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
	
	var simpleParser: SimpleParser {
		return SimpleParser(parser: csvParser)
	}
	
	var csvParser: CSVParser {
		let tok = UTF8DataTokenizer(data: data)
		let parser = CSVParser(tokenizer: tok)
		return parser
	}
	
	func makeIterator() -> SimpleParser {
		return simpleParser
	}
}

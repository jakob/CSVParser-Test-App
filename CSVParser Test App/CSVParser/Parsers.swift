//
//  Parsers.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class CSVParser: Sequence, IteratorProtocol, WarningProducer, PositionRetriever {
	internal var warnings = [CSVWarning]()
	private var inputIterator: TokenIterator
	private var config: CSVConfig
	private var rowOffset: Int = 0
	private var lineOffset: Int = 0
	
	init(inputIterator: TokenIterator, config: CSVConfig) {
		self.inputIterator = inputIterator
		self.config = config
	}
	
	func next() -> [CSVValue]? {
		var values = [CSVValue]()
		var currValue = ""
		var mode = CSVParsingMode.beforeQuote
		func appendValue() {
			let quoted = (mode == .beforeQuote) ? false : true
			let val = CSVValue(currValue, quoted: quoted)
			values.append(val)
			currValue = ""
			rowOffset += 1
		}
		func appendWarning(type: CSVWarning.WarningType) {
			let warning = CSVWarning(type: type, position: actualPosition())
			warnings.append(warning)
		}
		while let w = inputIterator.nextWarning() {
			warnings.append(w)
		}
		
		guard var token = inputIterator.next(), token.type != .endOfFile else { return nil }
		func appendToValue() {
			currValue.append(Character(token.content))
		}

		var lastEscapeToken: CSVToken?
		while true {
			
			//print("mode=\(mode), type=\(token.type), char=\(token.content)")
			
			switch (mode, token.type) {
			
			// escape character inside quote
			case (.insideQuote, .escape):
				lastEscapeToken = token
				mode = .escaped
				
			// quote or backslash in escaped mode
			case (.escaped, .quote), (.escaped, .escape):
				currValue.append(Character(token.content))
				mode = .insideQuote
				
			// unrecognized escaped character
			case (.escaped, _):
				if let content = lastEscapeToken?.content {
					currValue.append(Character(content))
					lastEscapeToken = nil
				}
				appendToValue()
				appendWarning(type: .unrecognizedEscapedCharacter)
				mode = .insideQuote
				
			case (_,.escape):
				appendWarning(type: .unexpectedEscape)
				appendToValue()
				
			case (.afterQuote, .quote):
				if config.quoteCharacter == config.escapeCharacter {
					appendToValue()
					mode = .insideQuote
				} else {
					appendWarning(type: .unexpectedQuote)
				}
				
			case (.afterQuote, .character):
				appendToValue()
				appendWarning(type: .unexpectedCharacter)
				
			case (_, .character):
				appendToValue()
				
			case (.insideQuote, .quote):
				mode = .afterQuote
				
			case (.insideQuote, .endOfFile):
				appendWarning(type: .unexpectedEOF)
				appendValue()
				return values
				
			case (.insideQuote, _):
				appendToValue()
				
			case (_, .delimiter):
				appendValue()
				mode = .beforeQuote
				
			case (.beforeQuote, .quote):
				if !currValue.isEmpty {
					appendToValue()
					appendWarning(type: .unexpectedQuote)
				} else {
					mode = .insideQuote
				}
				
			case (_, .lineSeparator), (_, .endOfFile):
				appendValue()
				return values
				
			default:
				fatalError("Impossible case: mode=\(mode), tokenType=\(token.type)")
			}
			
			guard let nextToken = inputIterator.next() else { return nil }
			token = nextToken
		}
	}
	
	func nextWarning() -> CSVWarning? {
		return warnings.isEmpty ? nil : warnings.removeFirst()
	}
	
	func actualPosition() -> Position {
		var position = inputIterator.actualPosition()
		position.rowOffset = rowOffset
		position.lineOffset = lineOffset
		return position
	}
}

class SimpleParser: Sequence, IteratorProtocol, WarningProducer, PositionRetriever {
	private var inputIterator: CSVParser
	private var lineOffset: Int = 0
	
	init(inputIterator: CSVParser) {
		self.inputIterator = inputIterator
	}
	
	func next() -> [String]? {
		guard let values = inputIterator.next() else { return nil }
		lineOffset += 1
		return values.map { $0.value ?? "" }
	}
	
	func nextWarning() -> CSVWarning? {
		return inputIterator.nextWarning()
	}
	
	func actualPosition() -> Position {
		var position = inputIterator.actualPosition()
		position.lineOffset = lineOffset
		return position
	}
}

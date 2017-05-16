//
//  Parsers.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class CSVParser<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer, PositionRetriever where InputIterator.Element == CSVToken {
	internal var warnings = [CSVWarning]()
	private var inputIterator: InputIterator
	private var config: CSVConfig
	private var rowOffset: Int = 0
	private var lineOffset: Int = 0
	
	init(inputIterator: InputIterator, config: CSVConfig) {
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
		
		if var warningProducer = inputIterator as? WarningProducer {
			while let w = warningProducer.nextWarning() {
				warnings.append(w)
			}
		}
		
		guard var token = inputIterator.next(), token.type != .endOfFile else { return nil }
		
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
				currValue += token.content
				mode = .insideQuote
				
			// unrecognized escaped character
			case (.escaped, _):
				if let content = lastEscapeToken?.content {
					currValue += content
					lastEscapeToken = nil
				}
				currValue += token.content
				appendWarning(type: .unrecognizedEscapedCharacter)
				mode = .insideQuote
				
			case (_,.escape):
				appendWarning(type: .unexpectedEscape)
				currValue += token.content
				
			case (.afterQuote, .quote):
				if config.quoteCharacter == config.escapeCharacter {
					currValue += token.content
					mode = .insideQuote
				} else {
					appendWarning(type: .unexpectedQuote)
				}
				
			case (.afterQuote, .character):
				currValue += token.content
				appendWarning(type: .unexpectedCharacter)
				
			case (_, .character):
				currValue += token.content
				
			case (.insideQuote, .quote):
				mode = .afterQuote
				
			case (.insideQuote, .endOfFile):
				appendWarning(type: .unexpectedEOF)
				appendValue()
				return values
				
			case (.insideQuote, _):
				currValue += token.content
				
			case (_, .delimiter):
				appendValue()
				mode = .beforeQuote
				
			case (.beforeQuote, .quote):
				if !currValue.isEmpty {
					currValue += token.content
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
		var position: Position
		if let positionRetriever = inputIterator as? PositionRetriever {
			position = positionRetriever.actualPosition()
		} else {
			position = Position()
		}
		position.rowOffset = rowOffset
		position.lineOffset = lineOffset
		return position
	}
}

class SimpleParser<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer, PositionRetriever where InputIterator.Element == [CSVValue] {
	private var inputIterator: InputIterator
	private var lineOffset: Int = 0
	
	init(inputIterator: InputIterator) {
		self.inputIterator = inputIterator
	}
	
	func next() -> [String]? {
		guard let values = inputIterator.next() else { return nil }
		lineOffset += 1
		return values.map { $0.value ?? "" }
	}
	
	func nextWarning() -> CSVWarning? {
		if var warningProducer = inputIterator as? WarningProducer {
			return warningProducer.nextWarning()
		}
		return nil
	}
	
	func actualPosition() -> Position {
		var position: Position
		if let positionRetriever = inputIterator as? PositionRetriever {
			position = positionRetriever.actualPosition()
		} else {
			position = Position()
		}
		position.lineOffset = lineOffset
		return position
	}
}

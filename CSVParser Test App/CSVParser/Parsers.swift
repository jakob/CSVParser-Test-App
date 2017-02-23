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
		func appendWarning(_ text: String) {
			let warning = CSVWarning(text: text)
			warnings.append(warning)
		}
		
		if var warningProducer = inputIterator as? WarningProducer {
			while let w = warningProducer.nextWarning() {
				warnings.append(w)
			}
		}
		
		guard var token = inputIterator.next(), token.type != .endOfFile else { return nil }
		
		while true {
			
			switch (mode, token.type) {
				
			case (.afterQuote, .quote):
				currValue += token.content
				mode = .insideQuote
				
			case (.afterQuote, .character):
				currValue += token.content
				appendWarning("Unexpected character after quote")
				
			case (_, .character):
				currValue += token.content
				
			case (.insideQuote, .quote):
				mode = .afterQuote
				
			case (.insideQuote, .endOfFile):
				appendWarning("Unexpected EOF while inside quote")
				appendValue()
				return values
				
			case (.insideQuote, _):
				currValue += token.content
				
			case (_, .delimiter):
				appendValue()
				mode = .beforeQuote
				
			case (.beforeQuote, .quote):
				if !currValue.isEmpty { appendWarning("Unexpected quote while value is empty") }
				mode = .insideQuote
				
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
	
	func currentPosition() -> CurrentPosition {
		var currPos: CurrentPosition
		if let positionRetriever = inputIterator as? PositionRetriever {
			currPos = positionRetriever.currentPosition()
		} else {
			currPos = CurrentPosition()
		}
		currPos.rowOffset = rowOffset
		currPos.lineOffset = lineOffset
		return currPos
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
	
	func currentPosition() -> CurrentPosition {
		var currPos: CurrentPosition
		if let positionRetriever = inputIterator as? PositionRetriever {
			currPos = positionRetriever.currentPosition()
		} else {
			currPos = CurrentPosition()
		}
		currPos.lineOffset = lineOffset
		return currPos
	}
}

//
//  TokenIterators.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class TokenIterator: WarningProducer, PositionRetriever {
	private var inputIterator: CodepointIterator
	private var config: CSVConfig
	private var tokenOffset: Int = 0
	
	init(inputIterator: CodepointIterator, config: CSVConfig) {
		self.inputIterator = inputIterator
		self.config = config
	}
	
	func next() -> CSVToken? {
		guard let char = inputIterator.next() else {
			return CSVToken(type: .endOfFile, content: UnicodeScalar(0))
		}
		
		let type: CSVToken.TokenType
		
		switch char {
		case config.delimiterCharacter:
			type = .delimiter
		case config.quoteCharacter:
			type = .quote
		case config.escapeCharacter:
			type = .escape
		case config.newlineCharacter:
			type = .lineSeparator
		default:
			type = .character
		}
		
		tokenOffset += 1
		
		let token = CSVToken(type: type, content: char)
		return token
	}
	
	func nextWarning() -> CSVWarning? {
		return inputIterator.nextWarning()
	}
	
	func actualPosition() -> Position {
		var position = inputIterator.actualPosition()
		position.tokenOffset = tokenOffset
		return position
	}
}

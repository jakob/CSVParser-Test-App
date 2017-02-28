//
//  TokenIterators.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class TokenIterator<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer, PositionRetriever where InputIterator.Element == UnicodeScalar {
	private var inputIterator: InputIterator
	private var config: CSVConfig
	private var tokenOffset: Int = 0
	
	init(inputIterator: InputIterator, config: CSVConfig) {
		self.inputIterator = inputIterator
		self.config = config
	}
	
	func next() -> CSVToken? {
		guard let char = inputIterator.next() else {
			return CSVToken(type: .endOfFile, content: "")
		}
		
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
		
		tokenOffset += 1
		
		let token = CSVToken(type: type, content: String(char))
		return token
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
		position.tokenOffset = tokenOffset
		return position
	}
}

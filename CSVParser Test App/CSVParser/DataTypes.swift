//
//  CSVParser.swift
//  CSVParser Test App
//
//  Created by Chris on 02/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

struct CSVConfig {
	var encoding = String.Encoding.utf8
	var delimiterCharacter: Character = ","
	var quoteCharacter: Character = "\""
	var escapeCharacter: Character = "\\"
	var decimalCharacter: Character = "."
	var newlineCharacter: Character = "\n"
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

struct CurrentPosition: CustomStringConvertible {
	var totalBytes: Int?
	var byteOffset: Int?
	var totalScalars: Int?
	var scalarOffset: Int?
	var tokenOffset: Int?
	var rowOffset: Int?
	var lineOffset: Int?
	var progress: Double? {
		guard let totalBytes = totalBytes, let byteOffset = byteOffset else { return nil }
		return Double(byteOffset) / Double(totalBytes)
	}
	var description: String {
		return "totalBytes=\(totalBytes), byteOffset=\(byteOffset), totalScalars=\(totalScalars), scalarOffset=\(scalarOffset), tokenOffset=\(tokenOffset), rowOffset=\(rowOffset), lineOffset=\(lineOffset), progress=\(progress)"
	}
}



protocol WarningProducer {
	mutating func nextWarning() -> CSVWarning?
}

protocol PositionRetriever {
	func currentPosition() -> CurrentPosition
}

class IteratorWithWarnings<Element>: IteratorProtocol, WarningProducer, PositionRetriever {
	internal var warnings = [CSVWarning]()
	
	func next() -> Element? {
		fatalError("This method is abstract")
	}
	
	func nextWarning() -> CSVWarning? {
		fatalError("This method is abstract")
	}
	
	func currentPosition() -> CurrentPosition {
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
	
	override func currentPosition() -> CurrentPosition {
		if let positionRetriever = iterator as? PositionRetriever {
			return positionRetriever.currentPosition()
		}
		return CurrentPosition()
	}
}

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
	var delimiterCharacter: UnicodeScalar = ","
	var quoteCharacter: UnicodeScalar = "\""
	var escapeCharacter: UnicodeScalar = "\\"
	var decimalCharacter: UnicodeScalar = "."
	var newlineCharacter: UnicodeScalar = "\n"
}

struct CSVToken: Equatable {
	enum TokenType {
		case character
		case delimiter
		case quote
		case escape
		case lineSeparator
		case endOfFile
	}
	var type: TokenType
	var content: UnicodeScalar
	
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
	enum WarningType {
		case fileOpenError
		case fileSizeError
		case invalidByteForUTF8Encoding
		case expectedUTF8ContinuationByte
		case unexpectedNilByte
		case unexpectedCharacter
		case unexpectedQuote
		case unexpectedEOF
		case unrecognizedEscapedCharacter
		case unexpectedEscape
		case invalidByteForEncoding
	}
	let type: WarningType
	let position: Position
	var text: String {
		switch type {
		case .fileOpenError:
			return "fileOpenError"
		case .fileSizeError:
			return "fileSizeError"
		case .invalidByteForUTF8Encoding:
			return "invalidByteForUTF8Encoding"
		case .expectedUTF8ContinuationByte:
			return "expectedUTF8ContinuationByte"
		case .unexpectedNilByte:
			return "unexpectedNilByte"
		case .unexpectedCharacter:
			return "unexpectedCharacter"
		case .unexpectedQuote:
			return "unexpectedQuote"
		case .unexpectedEOF:
			return "unexpectedEOF"
		case .unrecognizedEscapedCharacter:
			return "unrecognizedEscapedCharacter"
		case .unexpectedEscape:
			return "unexpectedEscape"
		case .invalidByteForEncoding:
			return "invalidByteForEncoding"
		}
	}
}

enum CSVParsingMode {
	case beforeQuote
	case insideQuote
	case afterQuote
	case escaped
}

struct Position: CustomStringConvertible {
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
	func actualPosition() -> Position
}

//
//  CSVDocument.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class CSVDocument: Sequence {
	private let fileURL: URL?
	private let sourceData: Data?
	private let sourceString: String?
	private let config: CSVConfig
	
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
	
	func makeIterator() -> AbstractIterator<[String]> {
		return ConcreteIterator(SimpleParser(inputIterator: makeCSVValueIterator()))
	}
	
	func makeCSVValueIterator() -> AbstractIterator<[CSVValue]> {
		let codepointIterator: AbstractIterator<UnicodeScalar>
		
		if let str = sourceString {
			codepointIterator = ConcreteIterator(str.unicodeScalars.makeIterator())
		} else {
			let byteIterator: AbstractIterator<UInt8>
			if let url = fileURL {
				byteIterator = ConcreteIterator(FileByteIterator(fileURL: url))
			} else if let data = sourceData {
				byteIterator = ConcreteIterator(DataByteIterator(data: data))
			} else {
				fatalError("This should be unreachable")
			}
			
			if config.encoding == .utf8 {
				codepointIterator = ConcreteIterator(UTF8CodepointIterator(inputIterator: byteIterator))
			} else {
				fatalError("Unsupported Character Encoding")
			}
		}
		
		let tokenIterator = TokenIterator(inputIterator: codepointIterator, config: config)
		let parser = CSVParser(inputIterator: tokenIterator, config: config)
		return ConcreteIterator(parser)
	}
	
}

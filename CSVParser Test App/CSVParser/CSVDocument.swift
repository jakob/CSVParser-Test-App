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
	var warnings = [CSVWarning]()
	
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
	
	
	func makeIterator() -> IteratorWithWarnings<[String]> {
		return ConcreteIteratorWithWarnings(SimpleParser(parser: makeCSVValueIterator()))
	}
	
	func makeCSVValueIterator() -> IteratorWithWarnings<[CSVValue]> {
		let codepointIterator: IteratorWithWarnings<UnicodeScalar>
		
		if let str = sourceString {
			codepointIterator = ConcreteIteratorWithWarnings(str.unicodeScalars.makeIterator())
		}
		else {
			let byteIterator: IteratorWithWarnings<UInt8>
			if let url = fileURL {
				byteIterator = ConcreteIteratorWithWarnings(FileByteIterator(fileURL: url))
			}
			else if let data = sourceData {
				byteIterator = ConcreteIteratorWithWarnings(DataByteIterator(data: data))
			}
			else {
				fatalError("This should be unreachable")
			}
			
			if config.encoding == .utf8 {
				codepointIterator = ConcreteIteratorWithWarnings(UTF8CodepointIterator(inputIterator: byteIterator))
			}
			else {
				fatalError("Unsupported Character Encoding")
			}
		}
		
		let tokenizer = TokenIterator(inputIterator: codepointIterator, config: config)
		let parser = CSVParser(inputIterator: tokenizer, config: config)
		return ConcreteIteratorWithWarnings(parser)
	}
	
}

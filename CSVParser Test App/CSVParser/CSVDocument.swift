//
//  CSVDocument.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class CSVDocument {
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
	
	func makeIterator() -> SimpleParser {
		return SimpleParser(inputIterator: makeCSVValueIterator())
	}
	
	func makeCSVValueIterator() -> CSVParser {
		let codepointIterator: CodepointIterator
		
		if let str = sourceString {
			codepointIterator = StringCodepointIterator(string: str)
		} else {
			let byteIterator: ByteIterator
			if let url = fileURL {
				if config.encoding == .utf8 {
					let data = try! Data(contentsOf: url)
					return FastCSVParserWrapper(data: data, config: config)
				}
				byteIterator = FileByteIterator(fileURL: url)
			} else if let data = sourceData {
				byteIterator = DataByteIterator(data: data)
			} else {
				fatalError("This should be unreachable")
			}
			
			if config.encoding == .utf8 {
				codepointIterator = UTF8CodepointIterator(inputIterator: byteIterator)
			} else {
				fatalError("Unsupported Character Encoding")
			}
		}
		
		let tokenIterator = TokenIterator(inputIterator: codepointIterator, config: config)
		let parser = SlowCSVParser(inputIterator: tokenIterator, config: config)
		return parser
	}
	
}

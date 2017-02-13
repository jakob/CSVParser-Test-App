//
//  ByteIterators.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 chrispysoft. All rights reserved.
//

import Foundation

class FileByteIterator: Sequence, IteratorProtocol, WarningProducer {
	internal var warnings = [CSVWarning]()
	
	private let fileURL: URL
	private var fileHandle: FileHandle?
	
	init(fileURL: URL) {
		self.fileURL = fileURL
	}
	
	deinit {
		fileHandle?.closeFile()
		fileHandle = nil
	}
	
	func next() -> UInt8? {
		if fileHandle == nil {
			fileHandle = FileHandle(forReadingAtPath: fileURL.path)
			if fileHandle == nil {
				warnings.append(CSVWarning(text: "File \(fileURL.lastPathComponent) could not be opened"))
			}
		}
		
		guard let data = fileHandle?.readData(ofLength: 1), data.count > 0 else { return nil }
		
		var byte: UInt8 = 0
		data.copyBytes(to: &byte, count: MemoryLayout<UInt8>.size)
		return byte
	}
	
	func nextWarning() -> CSVWarning? {
		return warnings.isEmpty ? nil : warnings.removeFirst()
	}
}

class DataByteIterator: Sequence, IteratorProtocol {
	private let data: Data
	private var index: Int = 0
	
	init(data: Data) {
		self.data = data
	}
	
	func next() -> UInt8? {
		if index < data.count {
			let byte = data[index]
			index += 1
			return byte
		}
		return nil
	}
}

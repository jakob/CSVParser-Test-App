//
//  ByteIterators.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class FileByteIterator: Sequence, IteratorProtocol, WarningProducer, PositionRetriever {
	internal var warnings = [CSVWarning]()
	private let fileURL: URL
	private var fileHandle: FileHandle?
	private var totalBytes: Int = 0
	private var byteOffset: Int = 0
	
	init(fileURL: URL) {
		self.fileURL = fileURL
		
		do {
			let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
			if let fileSize = attributes[FileAttributeKey.size] as? Int {
				totalBytes = fileSize
			}
		} catch {
			warnings.append(CSVWarning(text: "Error getting filesize of \(fileURL.lastPathComponent)"))
		}
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
		byteOffset += 1
		return byte
	}
	
	func nextWarning() -> CSVWarning? {
		return warnings.isEmpty ? nil : warnings.removeFirst()
	}
	
	func currentPosition() -> CurrentPosition {
		var currPos = CurrentPosition()
		currPos.totalBytes = totalBytes
		currPos.byteOffset = byteOffset
		return currPos
	}
}

class DataByteIterator: Sequence, IteratorProtocol, PositionRetriever {
	private let data: Data
	private var totalBytes: Int
	private var byteOffset: Int = 0
	
	init(data: Data) {
		self.data = data
		self.totalBytes = data.count
	}
	
	func next() -> UInt8? {
		if byteOffset < totalBytes {
			let byte = data[byteOffset]
			byteOffset += 1
			return byte
		}
		return nil
	}
	
	func currentPosition() -> CurrentPosition {
		var currPos = CurrentPosition()
		currPos.totalBytes = totalBytes
		currPos.byteOffset = byteOffset
		return currPos
	}
}

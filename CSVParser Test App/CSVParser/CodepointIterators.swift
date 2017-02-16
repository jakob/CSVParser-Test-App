//
//  CodepointIterators.swift
//  CSVParser Test App
//
//  Created by Chris on 07/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

let ItemReplacementChar = UnicodeScalar(0xFFFD)

class UTF8CodepointIterator<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer, PositionRetriever where InputIterator.Element == UInt8 {
	internal var warnings = [CSVWarning]()
	
	private var inputIterator: InputIterator
	private var returnedByte: UInt8?
	private var totalScalars: UInt64 = 0
	private var scalarOffset: UInt64 = 0
	
	
	init(inputIterator: InputIterator) {
		self.inputIterator = inputIterator
	}
	
	private func nextByte() -> UInt8? {
		if let b = returnedByte {
			returnedByte = nil
			return b
		}
		let nextByte = inputIterator.next()
		if var warningProducer = inputIterator as? WarningProducer {
			while let w = warningProducer.nextWarning() {
				warnings.append(w)
			}
		}
		return nextByte
	}
	
	private func returnByte(_ byte: UInt8) {
		if returnedByte != nil {
			fatalError("Returned byte is already set")
		}
		returnedByte = byte
	}
	
	
	func next() -> UnicodeScalar? {
		func appendWarning(_ text: String) {
			let warning = CSVWarning(text: text)
			warnings.append(warning)
			print("WARNING APPENDED")
		}
		
		guard let byte = nextByte() else {
			return nil
		}
		
		// single byte
		if (byte & 0b1000_0000) == 0 {
			return UnicodeScalar(byte)
		}
		
		// continuation byte
		else if (byte & 0b0100_0000) == 0 {
			appendWarning("Continuation byte at invalid position")
			return ItemReplacementChar
		}
		
		// first byte of two byte group
		else if (byte & 0b0010_0000) == 0 {
			let a = byte
			guard let b = nextByte() else {
				appendWarning("Expected second byte of group but found nil")
				return ItemReplacementChar
			}
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				returnByte(b)
				appendWarning("Expected continuation byte")
				return ItemReplacementChar
			}
			
			let res = UInt32(b & 0b111111) + (UInt32(a & 0b11111) << 6)
			return UnicodeScalar(res)
		}
		
		// first byte of three byte group
		else if (byte & 0b0001_0000) == 0 {
			
			let a = byte
			guard let b = nextByte() else {
				appendWarning("Expected second byte of group but found nil")
				return ItemReplacementChar
			}
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				returnByte(b)
				appendWarning("Expected continuation byte")
				return ItemReplacementChar
			}
			guard let c = nextByte() else {
				appendWarning("Expected third byte of group but found nil")
				return ItemReplacementChar
			}
			guard (c & 0b1100_0000) == 0b1000_0000 else {
				returnByte(c)
				appendWarning("Expected continuation byte")
				return ItemReplacementChar
			}
			
			let res = UInt32(c & 0b111111) + (UInt32(b & 0b111111) << 6) + (UInt32(a & 0b1111) << 12)
			return UnicodeScalar(res)
		}
		
		// first byte of four byte group
		else if (byte & 0b0000_1000) == 0 {
			
			let a = byte
			guard let b = nextByte() else {
				appendWarning("Expected second byte of group but found nil")
				return ItemReplacementChar
			}
			guard (b & 0b1100_0000) == 0b1000_0000 else {
				returnByte(b)
				appendWarning("Expected continuation byte")
				return ItemReplacementChar
			}
			guard let c = nextByte() else {
				appendWarning("Expected third byte of group but found nil")
				return ItemReplacementChar
			}
			guard (c & 0b1100_0000) == 0b1000_0000 else {
				returnByte(c)
				appendWarning("Expected continuation byte")
				return ItemReplacementChar
			}
			guard let d = nextByte() else {
				appendWarning("Expected fourth byte of group but found nil")
				return ItemReplacementChar
			}
			guard (d & 0b1100_0000) == 0b1000_0000 else {
				returnByte(d)
				appendWarning("Expected continuation byte")
				return ItemReplacementChar
			}
			
			let res = UInt32(d & 0b111111) + (UInt32(c & 0b111111) << 6) + (UInt32(b & 0b111111) << 12) + (UInt32(a & 0b1111) << 18)
			return UnicodeScalar(res)
			
		}
		
		// invalid byte
		else {
			appendWarning("Invalid byte")
			return ItemReplacementChar
		}
	}
	
	func nextWarning() -> CSVWarning? {
		return warnings.isEmpty ? nil : warnings.removeFirst()
	}
	
	func currentPosition() -> CurrentPosition? {
		if let positionRetriever = inputIterator as? PositionRetriever {
			var currPos = positionRetriever.currentPosition()
			currPos?.totalScalars = totalScalars
			currPos?.scalarOffset = scalarOffset
			return currPos
		}
		return nil
	}
}

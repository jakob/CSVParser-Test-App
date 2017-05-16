//
//  LatinCodepointIterator.swift
//  CSVParser Test App
//
//  Created by Patrick Steiner on 21.02.17.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class Latin1CodepointIterator<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer, PositionRetriever where InputIterator.Element == UInt8 {

	private var scalarOffset: Int = 0

    internal var warnings = [CSVWarning]()
    
    private var inputIterator: InputIterator
    private var returnedByte: UInt8?
    
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
		let position = actualPosition()
        guard let byte = nextByte() else {
            return nil
        }
        scalarOffset += 1
		
		let highbits = byte & 0xF0
		if highbits == 0x80 || highbits == 0x90 {
			if let string = String(bytes: [byte], encoding: .windowsCP1252) {
				return string.unicodeScalars.first!
			} else {
				warnings.append(CSVWarning(type: .invalidByteForEncoding, position: position))
				return ItemReplacementChar
			}
		} else {
			// Latin1 is a "subset" of Unicode, so the conversion is easy.
			// Mapping table: ftp://ftp.unicode.org/Public/MAPPINGS/ISO8859/8859-1.TXT
			return UnicodeScalar(byte)
		}
    }
    
    func nextWarning() -> CSVWarning? {
        return warnings.isEmpty ? nil : warnings.removeFirst()
    }
	
	func actualPosition() -> Position {
		var position: Position
		if let positionRetriever = inputIterator as? PositionRetriever {
			position = positionRetriever.actualPosition()
		} else {
			position = Position()
		}
		position.totalScalars = position.totalBytes
		position.scalarOffset = scalarOffset
		return position
	}

}

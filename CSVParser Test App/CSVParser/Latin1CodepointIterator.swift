//
//  LatinCodepointIterator.swift
//  CSVParser Test App
//
//  Created by Patrick Steiner on 21.02.17.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Foundation

class Latin1CodepointIterator<InputIterator: IteratorProtocol>: Sequence, IteratorProtocol, WarningProducer where InputIterator.Element == UInt8 {
    
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
        guard let byte = nextByte() else {
            return nil
        }
        
        // Latin1 is a "subset" of Unicode, so the conversion is easy.
        // Mapping table: ftp://ftp.unicode.org/Public/MAPPINGS/ISO8859/8859-1.TXT
        return UnicodeScalar(byte)
    }
    
    func nextWarning() -> CSVWarning? {
        return warnings.isEmpty ? nil : warnings.removeFirst()
    }
}

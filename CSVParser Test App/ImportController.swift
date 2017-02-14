//
//  ImportController.swift
//  CSVParser Test App
//
//  Created by Chris on 14/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Cocoa

class ImportController {
	
	static var activeImportControllers = [ImportController]()
	
	@IBOutlet var settingsWindow: NSWindow?
	
	
	func startImport() {
		ImportController.activeImportControllers.append(self)
		
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowsMultipleSelection = false
		openPanel.allowedFileTypes = ["csv"]
		
		
		//guard openPanel.runModal() == NSFileHandlingPanelOKButton, let fileURL = openPanel.urls.first else { return }
		
		
//		if openPanel.runModal() == NSFileHandlingPanelOKButton {
//			let fileURL = openPanel.urls.first!
//			let csvDoc = CSVDocument(fileURL: fileURL)
//			let iterator = csvDoc.makeIterator()
//			while let elem = iterator.next() {
//				while let warning = iterator.nextWarning() {
//					print("WARNING: \(warning.text)")
//				}
//				XCTAssertEqual(elem.count, expected[idx].count, "Line \(idx) does not have expected length")
//				XCTAssertEqual(elem, expected[idx], "Line \(idx) is not equal")
//			}
//			
//			while let warning = iterator.nextWarning() {
//				print("WARNING: \(warning.text)")
//			}
//		}
		
		Bundle.main.loadNibNamed("ImportWindow", owner: self, topLevelObjects: nil)
		settingsWindow?.makeKeyAndOrderFront(nil)
		
		
		
		
		// nremover self 
	}
	
}

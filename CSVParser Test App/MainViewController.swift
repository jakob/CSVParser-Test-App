//
//  MainViewController.swift
//  CSVParser Test App
//
//  Created by Chris on 14/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
	
	@IBAction func importCSVFile(_ sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowsMultipleSelection = false
		openPanel.allowedFileTypes = ["csv"]
		
		if openPanel.runModal() == NSFileHandlingPanelOKButton {
			let importController = ImportController(fileURL: openPanel.url!)
			importController.loadWindow()
			importController.previewImport()
		}
		
		//let fileURL = URL(fileURLWithPath: "/Users/chris/Documents/gemeinden_at.csv")
		//let importController = ImportController(fileURL: fileURL)
		//importController.loadWindow()
		//importController.previewImport()
	}
	
}

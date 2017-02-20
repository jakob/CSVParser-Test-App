//
//  ImportController.swift
//  CSVParser Test App
//
//  Created by Chris on 14/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Cocoa

class ImportController: NSObject {
	
	private static var activeImportControllers = [ImportController]()
	
	fileprivate var tableData = [[String]]()
	private var headerData = [String]()
	
	private var fileURL: URL?
	
	private var delimiterCharacter: Character {
		var char: String
		let selIdx = delimiterSegControl?.selectedSegment ?? 0
		switch selIdx {
			case 0: char = ","
			case 1: char = ";"
			case 2: char = "\t"
			case 3: char = "|"
			default: char = ","
		}
		return Character(char)
	}
	private var decimalCharacter: Character {
		var char: String
		let selIdx = decimalSegControl?.selectedSegment ?? 0
		switch selIdx {
			case 0: char = "."
			case 1: char = ","
			default: char = "."
		}
		return Character(char)
	}
	private var quoteCharacter: Character {
		var char: String
		let selIdx = quoteSegControl?.selectedSegment ?? 0
		switch selIdx {
			case 0: char = "\""
			case 1: char = ""
			case 2: char = ""
			default: char = "\""
		}
		return Character(char)
	}
	private var encoding: String.Encoding {
		guard let selectedItem = encodingPopupButton?.selectedItem else { return .utf8 }
		switch selectedItem.title {
			case "UTF-8": return .utf8
			default: return .utf8
		}
	}
	private var firstRowAsHeader: Bool {
		guard let checkbox = firstRowAsHeaderCheckbox else { return false }
		return checkbox.state == NSOnState
	}
	private var importNumRows = 10
	
	@IBOutlet var settingsWindow: NSWindow?
	@IBOutlet var delimiterSegControl: NSSegmentedControl?
	@IBOutlet var decimalSegControl: NSSegmentedControl?
	@IBOutlet var quoteSegControl: NSSegmentedControl?
	@IBOutlet var encodingPopupButton: NSPopUpButton?
	@IBOutlet var firstRowAsHeaderCheckbox: NSButton?
	@IBOutlet var tableView: NSTableView?
	
	
	@IBAction func configChanged(_ sender: AnyObject?) {
		importFile()
	}
	
	
	func startImport() {
		ImportController.activeImportControllers.append(self)
		
		Bundle.main.loadNibNamed("ImportWindow", owner: self, topLevelObjects: nil)
		settingsWindow?.makeKeyAndOrderFront(nil)
		
		/*
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowsMultipleSelection = false
		openPanel.allowedFileTypes = ["csv"]
		
		if openPanel.runModal() == NSFileHandlingPanelOKButton {
			fileURL = openPanel.urls.first!
			importFile()
		}
		*/
		
		fileURL = URL(fileURLWithPath: "/Users/chris/Documents/gemeinden_at.csv")
		importFile()
		
		// remove self from activeImportControllers
	}
	
	func importFile() {
		var config = CSVConfig()
		config.delimiterCharacter = delimiterCharacter
		config.decimalCharacter = decimalCharacter
		config.quoteCharacter = quoteCharacter
		config.encoding = encoding
		
		guard let fileURL = fileURL else { print("fileURL is nil"); return }
		
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		var nRows = 0
		var nColumns = 0
		
		tableData.removeAll()
		headerData.removeAll()
		
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() { print("WARNING: \(warning.text)") }
			
			print(iterator.currentPosition())
			
			if firstRowAsHeader && nRows == 0 {
				headerData.append(contentsOf: elem)
			} else {
				tableData.append(elem)
			}
			
			if elem.count > nColumns {
				nColumns = elem.count
			}
			
			nRows += 1
			
			if nRows >= importNumRows {
				break
			}
		}
		while let warning = iterator.nextWarning() { print("WARNING: \(warning.text)") }
		
		while let col = tableView?.tableColumns.last {
			tableView?.removeTableColumn(col)
		}
		for i in 0..<nColumns {
			let col = NSTableColumn(identifier: "\(i)")
			if firstRowAsHeader && headerData.indices.contains(i) {
				col.headerCell.title = headerData[i]
			}
			tableView?.addTableColumn(col)
		}
		
		tableView?.reloadData()
	}
}

extension ImportController: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return tableData.count
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		guard let identifier = tableColumn?.identifier else { return nil }
		guard let col = Int(identifier) else { return nil }
		guard tableData.indices.contains(row) else { return nil }
		let rowData = tableData[row]
		guard rowData.indices.contains(col) else { return nil }
		return rowData[col]
	}
}

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
	
	@IBOutlet var importWindow: NSWindow?
	@IBOutlet var delimiterSegControl: NSSegmentedControl?
	@IBOutlet var decimalSegControl: NSSegmentedControl?
	@IBOutlet var quoteSegControl: NSSegmentedControl?
	@IBOutlet var encodingPopupButton: NSPopUpButton?
	@IBOutlet var firstRowAsHeaderCheckbox: NSButton?
	@IBOutlet var tableView: NSTableView?
	
	private var progressWindowController: ProgressWindowController?
	
	fileprivate var tableData = [[String]]()
	private var headerData = [String]()
	private var fileURL: URL?
	private var delimiterCharacter: UnicodeScalar {
		var char: String
		let selIdx = delimiterSegControl?.selectedSegment ?? 0
		switch selIdx {
			case 0: char = ","
			case 1: char = ";"
			case 2: char = "\t"
			case 3: char = "|"
			default: char = ","
		}
		return UnicodeScalar(char)!
	}
	private var decimalCharacter: UnicodeScalar {
		var char: String
		let selIdx = decimalSegControl?.selectedSegment ?? 0
		switch selIdx {
			case 0: char = "."
			case 1: char = ","
			default: char = "."
		}
		return UnicodeScalar(char)!
	}
	private var quoteCharacter: UnicodeScalar {
		var char: String
		let selIdx = quoteSegControl?.selectedSegment ?? 0
		switch selIdx {
			case 0: char = "\""
			case 1: char = ""
			case 2: char = ""
			default: char = "\""
		}
		return UnicodeScalar(char)!
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
	
	
	init(fileURL: URL) {
		self.fileURL = fileURL
	}
	
	func loadWindow() {
		ImportController.activeImportControllers.append(self)
		
		Bundle.main.loadNibNamed("ImportWindow", owner: self, topLevelObjects: nil)
		importWindow?.makeKeyAndOrderFront(nil)
		
		// remove self from activeImportControllers
	}
	
	func previewImport(importRows: Int = 10) {
		var config = CSVConfig()
		config.delimiterCharacter = delimiterCharacter
		config.decimalCharacter = decimalCharacter
		config.quoteCharacter = quoteCharacter
		config.encoding = encoding
		
		guard let fileURL = fileURL else { print("fileURL is nil"); return }
		
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		var rowIdx = 0
		var colIdx = 0
		
		tableData.removeAll()
		headerData.removeAll()
		
		while let elem = iterator.next() {
			while let warning = iterator.nextWarning() { print("WARNING: \(warning.text)") }
			
			print(iterator.actualPosition())
			
			if firstRowAsHeader && rowIdx == 0 {
				headerData.append(contentsOf: elem)
			} else {
				tableData.append(elem)
			}
			
			if elem.count > colIdx {
				colIdx = elem.count
			}
			
			rowIdx += 1
			
			if rowIdx >= importRows {
				break
			}
		}
		while let warning = iterator.nextWarning() { print("WARNING: \(warning.text)") }
		
		while let col = tableView?.tableColumns.last {
			tableView?.removeTableColumn(col)
		}
		for i in 0..<colIdx {
			let col = NSTableColumn(identifier: "\(i)")
			if firstRowAsHeader && headerData.indices.contains(i) {
				col.headerCell.title = headerData[i]
			}
			tableView?.addTableColumn(col)
		}
		
		tableView?.reloadData()
	}
	
	@IBAction func configChanged(_ sender: AnyObject?) {
		previewImport()
	}
	
	@IBAction func closeImportWindow(_ sender: AnyObject?) {
		importWindow?.close()
		if let index = ImportController.activeImportControllers.index(of: self) {
			ImportController.activeImportControllers.remove(at: index)
		}
	}
	
	
	@IBAction func startImport(_ sender: AnyObject?) {
		progressWindowController = ProgressWindowController(windowNibName: "ProgressWindow")
		guard progressWindowController != nil else {
			print("Error loading ProgressWindowController")
			return
		}
		
		importWindow?.beginSheet(progressWindowController!.window!, completionHandler: { (modalResponse) in })
		
		var config = CSVConfig()
		config.delimiterCharacter = delimiterCharacter
		config.decimalCharacter = decimalCharacter
		config.quoteCharacter = quoteCharacter
		config.encoding = encoding
		
		guard let fileURL = fileURL else { print("fileURL is nil"); return }
		
		let csvDoc = CSVDocument(fileURL: fileURL, config: config)
		let iterator = csvDoc.makeIterator()
		
		DispatchQueue.global().async {
			var lastTime = Date().timeIntervalSince1970
			let updateInterval = 0.020
			var shouldReport = true
			
			while let _ = iterator.next(), self.progressWindowController!.didCancel == false {
				if let progress = iterator.actualPosition().progress {
					if shouldReport && Date().timeIntervalSince1970 >= lastTime+updateInterval {
						lastTime = Date().timeIntervalSince1970
						shouldReport = false
						DispatchQueue.main.async {
							self.progressWindowController?.setProgress(progress)
							shouldReport = true
						}
					}
				}
			}
			DispatchQueue.main.async {
				self.importWindow?.endSheet(self.progressWindowController!.window!)
			}
		}
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

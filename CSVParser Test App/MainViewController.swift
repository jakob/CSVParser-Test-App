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
		let importController = ImportController()
		importController.startImport()
	}
	
}

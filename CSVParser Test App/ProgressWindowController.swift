//
//  ProgressWindowController.swift
//  CSVParser Test App
//
//  Created by Chris on 21/02/2017.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

import Cocoa

class ProgressWindowController: NSWindowController {
	
	@IBOutlet var progressIndicator: NSProgressIndicator!
	var didCancel = false
	
	func setProgress(_ value: Double) {
		progressIndicator.doubleValue = value
	}
	
	@IBAction func cancel(_ sender: AnyObject?) {
		didCancel = true
	}
	
}

//
//  ViewController.swift
//  GoogleServiceGenerator
//
//  Created by Matthew Wyskiel on 10/17/15.
//  Copyright © 2015 Matthew Wyskiel. All rights reserved.
//

import Cocoa
import GoogleAPIs

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear() {
        loadData()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    var apiList: DiscoveryDirectoryList!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet weak var directoryTextField: NSTextField!
    
    func loadData() {
        Discovery.sharedInstance.preferred = true
        Discovery.sharedInstance.listAPIs { (list, error) -> () in
            if list != nil {
                self.apiList = list!
                print(list)
                self.tableView.reloadData()
            } else if error != nil {
                print(error)
            }
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return (apiList != nil) ? apiList.items.count : 0
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let api = apiList[row]
        return "\(api.title), \(api.version)"
    }
    
    @IBAction func generate(sender: AnyObject) {
        let directory = directoryTextField.stringValue
        let serviceName = apiList[tableView.selectedRow].name
        let serviceVersion = apiList[tableView.selectedRow].version
        
        Generator.sharedInstance.generate(serviceName: serviceName, version: serviceVersion, destinationPath: directory) { (success, error) -> () in
            let alert = NSAlert()
            alert.addButtonWithTitle("OK")
            if success {
                alert.messageText = "Success!"
                alert.informativeText = "Files successfully generated."
            } else if error != nil {
                alert.messageText = "Error"
                alert.informativeText = error.debugDescription
            }
            alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        }
    }
    
}


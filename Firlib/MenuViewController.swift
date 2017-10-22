//
//  ViewController.swift
//  Firlib
//
//  Created by Henrik Engström on 2017-10-14.
//

import Cocoa
import Foundation

class MenuViewController: NSViewController {
    @IBOutlet weak var pythonPathControl: NSPathControl!
    @IBOutlet weak var irlibPathControl: NSPathControl!
    
    @IBAction func pickPythonPath(_ sender: Any) {
        let path = openFileDialog(canChooseDirectories: false, canChooseFiles: true)
        if path != nil {
            pythonPathControl.stringValue = path!
            let defaults = UserDefaults.standard
            defaults.setValue(path!, forKeyPath: "pythonPath")
        }
    }
    
    @IBAction func pickIrlibPath(_ sender: Any) {
        let path = openFileDialog(canChooseDirectories: true, canChooseFiles: false)
        if path != nil {
            irlibPathControl.stringValue = path!
            let defaults = UserDefaults.standard
            defaults.setValue(path!, forKeyPath: "irlibPath")
        }
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        let url = "https://github.com/njwilson23/irlib/archive/master.zip"
        let _ = HelperFunctions().shell(launchPath: "/usr/bin/open", arguments: ["-a", "safari", url])
    }
    
    @IBAction func tutorialButtonClicked(_ sender: Any) {
        let url = "https://github.com/njwilson23/irlib/blob/master/doc/doc_tutorial.rst"
        let _ = HelperFunctions().shell(launchPath: "/usr/bin/open", arguments: ["-a", "safari", url])
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        self.view.wantsLayer = true
        let color : CGColor = CGColor(red: 1, green: 1, blue: 1.0, alpha: 0.95)
        self.view.layer?.backgroundColor = color
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // File browser dialog
    func openFileDialog(canChooseDirectories: Bool = true, canChooseFiles: Bool = true) -> String? {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose python binary";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = canChooseDirectories;
        dialog.canChooseFiles          = canChooseFiles;
        dialog.allowsMultipleSelection = false;
        //dialog.allowedFileTypes        = ["txt"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            if (result != nil) {
                let path = result!.path
                return path
            }
        } else {
            // User clicked on "Cancel"
        }
        return nil
    }
}

class AboutViewController: NSViewController {
    let version: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
   var logoClicked = 0
    
    @IBOutlet weak var versionLabel: NSTextField!
    
    @IBAction func logoClicked(_ sender: Any) {
        self.logoClicked += 1
        
        if self.logoClicked == 10 {
            var url: URL
            if let resourcePath = Bundle.main.resourcePath {
                let fileName = "www/fanny_color.html"
                let htmlPath = resourcePath + "/" + fileName
                url = URL(fileURLWithPath: htmlPath)
                let _ = HelperFunctions().shell(launchPath: "/usr/bin/open", arguments: ["-a", "safari", url.path])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.wantsLayer = true
        let color : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
        self.view.layer?.backgroundColor = color
        
        self.versionLabel.stringValue = "Version \(version as! String)"
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

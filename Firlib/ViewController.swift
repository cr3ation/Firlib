//
//  ViewController.swift
//  Firlib
//
//  Created by Henrik Engström on 2017-10-14.
//

import Cocoa

class ViewController: NSViewController {
    var irlibPath: String = ""
    let statusAvailable = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))
    let statusNone = NSImage(named: NSImage.Name(rawValue: "NSStatusNone"))
    let statusPartiallyAvailable = NSImage(named: NSImage.Name(rawValue: "NSStatusPartiallyAvailable"))
    
    var timer = Timer()     // Updates GUI
    var timer2 = Timer()    // Look for irlib folder
    
    // Working on
    var workingOnUtmFile = false
    var workingOnChaces = false
    
    //var pickManagers: [PickManager] = []
    var selectedIndex = 0
    
    @IBOutlet weak var h5FileSelector: NSPopUpButton!
    @IBOutlet weak var dumpMetaButton: NSButton!
    @IBOutlet weak var utmCoordinatesButton: NSButton!
    @IBOutlet weak var cachesButton: NSButton!
    @IBOutlet weak var pickedButton: NSButton!
    @IBOutlet weak var ratedButton: NSButton!
    @IBOutlet weak var offsetsButton: NSButton!
    
    @IBOutlet weak var cachesLabel: NSTextField!
    
    @IBOutlet weak var pickedLabel: NSTextField!
    
    @IBOutlet weak var ratedLabel: NSTextField!
    
    // When a new file is selected in drop down
    @IBAction func newFileSelected(_ sender: Any) {
        updateGuiComponents()
    }

    @IBAction func dumpMetaButtonClicked(_ sender: Any) {
        dumpMetaButton.isEnabled = false;
        getCurretPickManager().generateMetadata()
    }
    
    @IBAction func utmCoordinatesButtonClicked(_ sender: Any) {
        utmCoordinatesButton.isEnabled = false
        utmCoordinatesButton.image = statusPartiallyAvailable
        workingOnUtmFile = true
        getCurretPickManager().generateUtmFile()
    }
    
    @IBAction func cachesButtonClicked(_ sender: Any) {
        cachesButton.isEnabled = false
        cachesButton.image = statusPartiallyAvailable
        workingOnChaces = true
        getCurretPickManager().generateCaches()
    }
 
    @IBAction func pickedButtonClicked(_ sender: Any) {
        getCurretPickManager().openIcepick2()
    }
    
    @IBAction func ratedButtonClicked(_ sender: Any) {
        getCurretPickManager().openIcerate()
    }

    @IBAction func offsetsButtonClicked(_ sender: Any) {
        getCurretPickManager().generateOffsets()
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //let defaults = UserDefaults.standard
        //defaults.removeObject(forKey: "pythonPath")
        //defaults.removeObject(forKey: "irlibPath")
        initialSetup()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // Returns the selected pickManager
    func getCurretPickManager() -> PickManager {
        let file = h5FileSelector.titleOfSelectedItem
        let h5FileUrl = URL(fileURLWithPath: irlibPath).appendingPathComponent("data").appendingPathComponent(file!)
        let pickManager = PickManager(h5FileUrl: h5FileUrl, irlibUrl: URL(fileURLWithPath: irlibPath))
        return pickManager
    }
    
    // Initial setup
    @objc func initialSetup(){
        // Load python path
        let defaults = UserDefaults.standard
        
        let pythonPath = defaults.value(forKey: "pythonPath")
        if pythonPath == nil {
            defaults.setValue("/usr/bin/python", forKeyPath: "pythonPath")
        }
        // Load irlib path
        let irlibPath = defaults.value(forKey: "irlibPath")
        if irlibPath == nil {
            if !timer2.isValid {
                let (_) = dialogOK(question: "Welcome to Firlib! Time to set things up...", text: "It looks like you haven't selected where your irlib folder is. Open Preferences... (⌘,) and select your irlib directory. \n\nWhile you're at it you may want to select another python environment as well.")
                timer2 = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.initialSetup), userInfo: nil, repeats: true)
            }
            return
        } else {
            self.irlibPath = defaults.value(forKey: "irlibPath") as! String
            timer2.invalidate()
        }
        
        // Find h5 files in data folder
        let h5FilesUrl = getH5Files()
        self.h5FileSelector.removeAllItems()
        if h5FilesUrl.count == 0 { return }
        for h5FileUrl in h5FilesUrl{
            let fileName = h5FileUrl.pathComponents.last
            self.h5FileSelector.addItem(withTitle: fileName!)
        }
        //Start timer
        updateGuiComponents()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateGuiNow), userInfo: nil, repeats: true)
    }

    // Get all h5 files in folder (not _utm.h5)
    func getH5Files() -> [URL]{
        let irlibUrl = URL(fileURLWithPath: irlibPath)
        let dataUrl = irlibUrl.appendingPathComponent("data")
        
        let filesUrl = contentsOf(folder: dataUrl)
        var h5Files: [URL] = []
        
        // All h5 files, not _utm.h5
        for fileUrl in filesUrl {
            var pathComponents = fileUrl.pathComponents
            
            // Files ending on h5 but not _utm.h5
            if fileUrl.pathExtension == "h5" &&
                pathComponents[pathComponents.count - 1].lowercased().range(of:"_utm.h5") == nil {
                h5Files.append(fileUrl)
            }
        }
        return h5Files
    }
    
    // Returns all files in folder
    func contentsOf(folder: URL) -> [URL] {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            let urls = contents.map { return folder.appendingPathComponent($0) }
            return urls
        } catch {
            print(error)
            return []
        }
    }
    
    // Only used by timer
    @objc func updateGuiNow() {
        updateGuiComponents()
    }
    
    // Validate GUI
    func updateGuiComponents()
    {
        //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay), execute: {
            //let pickManager = pickManagers[selectedIndex]
            let pickManager = self.getCurretPickManager()
            
            // Dump metadata
            if pickManager.dumpmetaFileExists {
                self.dumpMetaButton.isEnabled = false
                self.dumpMetaButton.image = self.statusAvailable
            }
            else {
                self.dumpMetaButton.isEnabled = true
                self.dumpMetaButton.image = self.statusNone
                
            }
            
            // Utm coordinates
            if pickManager.utmFileExists {
                self.utmCoordinatesButton.isEnabled = false
                self.utmCoordinatesButton.image = self.statusAvailable
                self.workingOnUtmFile = false
            }
            else {
                if self.workingOnUtmFile {
                    self.utmCoordinatesButton.image = self.statusPartiallyAvailable
                }
                else {
                    self.utmCoordinatesButton.isEnabled = true
                    self.utmCoordinatesButton.image = self.statusNone
                }
            }
            
            // Caches
            if pickManager.utmFileExists {
                if pickManager.cacheFilesExist {
                    self.cachesButton.isEnabled = false
                    self.cachesButton.image = self.statusAvailable
                    self.cachesLabel.stringValue = "Caches (\(pickManager.cacheFilesUrls.count) lines)"
                    self.workingOnChaces = false
                }
                else {
                    if self.workingOnChaces  {
                        self.cachesButton.image = self.statusPartiallyAvailable
                        self.cachesButton.isEnabled = false
                    }
                    else {
                        self.cachesButton.isEnabled = true
                        self.cachesButton.image = self.statusNone
                    }
                    self.cachesLabel.stringValue = "Caches"
                }
            }
            else {
                self.cachesButton.isEnabled = false
                self.cachesButton.image = self.statusNone
                self.cachesLabel.stringValue = "Caches"
            }
            
            // Picked
            if pickManager.cacheFilesExist {
                self.pickedButton.isEnabled = true
                if pickManager.pickedFilesExist {
                    if pickManager.cacheFilesUrls.count == pickManager.pickedLines.count {
                        self.pickedButton.image = self.statusAvailable
                    }
                    else {
                        self.pickedButton.image = self.statusPartiallyAvailable
                    }
                    let pickedLines = self.getNumberArrayAsString(numbers: pickManager.pickedLines)
                    self.pickedLabel.stringValue = "Picked lines (\(pickedLines))"
                }
                else {
                    self.pickedButton.image = self.statusPartiallyAvailable
                    self.pickedLabel.stringValue = "Picked"
                }
            }
            else {
                self.pickedButton.isEnabled = false
                self.pickedButton.image = self.statusNone
                self.pickedLabel.stringValue = "Picked"
            }
            
            // Rated
            if pickManager.cacheFilesExist {
                self.ratedButton.isEnabled = true
                if pickManager.ratedLines.count > 0 {
                    if pickManager.cacheFilesUrls.count == pickManager.ratedLines.count {
                        self.ratedButton.image = self.statusAvailable
                    }
                    else {
                        self.ratedButton.image = self.statusPartiallyAvailable
                    }
                    let ratedLines = self.getNumberArrayAsString(numbers: pickManager.ratedLines)
                    self.ratedLabel.stringValue = "Rated lines (\(ratedLines))"
                }
                else {
                    self.ratedButton.image = self.statusPartiallyAvailable
                    self.ratedLabel.stringValue = "Rated"
                }
            }
            else {
                self.ratedButton.isEnabled = false
                self.ratedButton.image = self.statusNone
                self.ratedLabel.stringValue = "Rated"
            }
            
            // Offsets
            if pickManager.dumpmetaFileExists {
                if pickManager.offsetFileExists {
                    self.offsetsButton.isEnabled = true
                    self.offsetsButton.image = self.statusAvailable
                }
                else {
                    self.offsetsButton.isEnabled = true
                    self.offsetsButton.image = self.statusNone
                }
            }
            else {
                self.offsetsButton.isEnabled = false
                self.offsetsButton.image = self.statusNone
            }
        //})
    }
    
    func getNumberArrayAsString(numbers: [Int]) -> String {
        var returnString = ""
        var i = 0
        for number in numbers {
            if i != 0 { returnString.append(", ") }
            returnString.append(String(number))
            i += 1
        }
        return returnString
    }
    
    func dialogOK(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }
}


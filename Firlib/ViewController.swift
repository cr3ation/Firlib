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
    var workingOnOffset = false
    var workingOnResult = false
    
    //var pickManagers: [PickManager] = []
    var selectedIndex = 0
    
    @IBOutlet weak var h5FileSelector: NSPopUpButton!
    @IBOutlet weak var dumpMetaButton: NSButton!
    @IBOutlet weak var utmCoordinatesButton: NSButton!
    @IBOutlet weak var cachesButton: NSButton!
    @IBOutlet weak var pickedButton: NSButton!
    @IBOutlet weak var ratedButton: NSButton!
    @IBOutlet weak var offsetsButton: NSButton!
    @IBOutlet weak var resultButton: NSButton!
    
    
    
    @IBOutlet weak var cachesLabel: NSTextField!
    @IBOutlet weak var pickedLabel: NSTextField!
    @IBOutlet weak var ratedLabel: NSTextField!
    @IBOutlet weak var offsetLabel: NSTextField!
    
    // When a new file is selected in drop down
    @IBAction func newFileSelected(_ sender: Any) {
        updateGuiComponents()
    }

    @IBAction func dumpMetaButtonClicked(_ sender: Any) {
        let pickManager = getCurretPickManager()
        if pickManager.dumpmetaFileExists {
            let (_) = pickManager.shell(launchPath: "/usr/bin/open", arguments: [pickManager.dumpmetaFileUrl.path])
            return
        }
        dumpMetaButton.isEnabled = false;
        pickManager.generateMetadata()
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
        let pickManager = getCurretPickManager()
        if offsetsButton.image == statusAvailable {
            let (_) = pickManager.shell(launchPath: "/usr/bin/open", arguments: [pickManager.offsetFileUrl.path])
            return
        }
        offsetsButton.isEnabled = false
        offsetsButton.image = statusPartiallyAvailable
        workingOnOffset = true
        pickManager.generateOffsets()
    }
    
    @IBAction func resultButtonClicked(_ sender: Any) {
        let pickManager = getCurretPickManager()
        if resultButton.image == statusAvailable {
            let (_) = pickManager.shell(launchPath: "/usr/bin/open", arguments: [pickManager.iceThicknessFileUrl.path])
            return
        }
        resultButton.isEnabled = false
        resultButton.image = statusPartiallyAvailable
        workingOnResult = true
        getCurretPickManager().generateResult()
    }
    


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.wantsLayer = true
        let color : CGColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
        self.view.layer?.backgroundColor = color
        
        //let defaults = UserDefaults.standard
        //defaults.removeObject(forKey: "pythonPath")
        //defaults.removeObject(forKey: "irlibPath")
        //defaults.removeObject(forKey: "antennaSpacing")
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
        
        // Load python path from defaults
        let pythonPath = defaults.value(forKey: "pythonPath")
        if pythonPath == nil {
            defaults.setValue("/usr/bin/python", forKeyPath: "pythonPath")
        }
        let antennaSpacing = defaults.integer(forKey: "antennaSpacing")
        if antennaSpacing == 0 {
            defaults.set(60, forKey: "antennaSpacing")
        }
        // Load irlib path from defaults
        let irlibPath = defaults.value(forKey: "irlibPath")
        if irlibPath == nil {
            if !timer2.isValid {
                let (_) = dialogOK(question: "Welcome to Firlib! Time to set things up...", text: "It looks like you haven't selected where your irlib folder is. Open Preferences (⌘,) and select your irlib directory. \n\nWhile you're at it you may want to select another python environment and set the antenna spacing as well.")
                timer2 = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.initialSetup), userInfo: nil, repeats: true)
            }
            return
        } else {
            self.irlibPath = defaults.value(forKey: "irlibPath") as! String
            timer2.invalidate()
        }
        
        // Find h5 files in data folder
        let h5Files = getH5Files()
        self.h5FileSelector.removeAllItems()
        if h5Files.count == 0 { return }
        for file in h5Files{
            self.h5FileSelector.addItem(withTitle: file)
        }
        
        //Start timer
        updateGuiComponents()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateGuiNow), userInfo: nil, repeats: true)
    }

    // Get all h5 files in folder (not _utm.h5)
    func getH5Files() -> [String] {
        let irlibUrl = URL(fileURLWithPath: irlibPath)
        let dataUrl = irlibUrl.appendingPathComponent("data")
        
        let filesUrl = contentsOf(folder: dataUrl)
        var h5FileNames: [String] = []
        
        // All h5 files, not _utm.h5
        for fileUrl in filesUrl {
            let pathComponents = fileUrl.pathComponents
            
            // Files ending on h5 but not _utm.h5
            if fileUrl.pathExtension == "h5" &&
                pathComponents.last?.lowercased().range(of:"_utm.h5") == nil {
                h5FileNames.append(fileUrl.pathComponents.last!)
            }
        }
        return h5FileNames.sorted()
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
                self.dumpMetaButton.isEnabled = true
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
                    let cachedLines = self.getNumberArrayAsString(numbers: pickManager.cachedLines)
                    self.cachesLabel.stringValue = "Line \(cachedLines)"
                    //self.cachesLabel.stringValue = "\(pickManager.cacheFilesUrls.count) lines"
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
                    self.cachesLabel.stringValue = ""
                }
            }
            else {
                self.cachesButton.isEnabled = false
                self.cachesButton.image = self.statusNone
                self.cachesLabel.stringValue = ""
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
                    self.pickedLabel.stringValue = "Line \(pickedLines)"
                }
                else {
                    self.pickedButton.image = self.statusPartiallyAvailable
                    self.pickedLabel.stringValue = ""
                }
            }
            else {
                self.pickedButton.isEnabled = false
                self.pickedButton.image = self.statusNone
                self.pickedLabel.stringValue = ""
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
                    self.ratedLabel.stringValue = "Line \(ratedLines)"
                }
                else {
                    self.ratedButton.image = self.statusPartiallyAvailable
                    self.ratedLabel.stringValue = ""
                }
            }
            else {
                self.ratedButton.isEnabled = false
                self.ratedButton.image = self.statusNone
                self.ratedLabel.stringValue = ""
            }
            
            // Offsets
            if pickManager.dumpmetaFileExists {
                if pickManager.offsetFileExists {
                    self.offsetsButton.isEnabled = true
                    self.offsetsButton.image = self.statusAvailable
                    workingOnOffset = false
                }
                else {
                    if workingOnOffset {
                        self.offsetsButton.image = self.statusPartiallyAvailable
                        self.offsetsButton.isEnabled = false
                    } else {
                        self.offsetsButton.isEnabled = true
                        self.offsetsButton.image = self.statusNone
                    }
                }
            }
            else {
                self.offsetsButton.isEnabled = false
                self.offsetsButton.image = self.statusNone
            }
        
        // Result
        if pickManager.offsetFileExists {
            if pickManager.iceThicknessFileExists {
                self.resultButton.isEnabled = true
                self.resultButton.image = self.statusAvailable
                workingOnResult = false
            }
            else {
                if workingOnResult {
                    self.resultButton.image = self.statusPartiallyAvailable
                    self.resultButton.isEnabled = false
                } else {
                    self.resultButton.isEnabled = true
                    self.resultButton.image = self.statusNone
                }
            }
        }
        else {
            self.resultButton.isEnabled = false
            self.resultButton.image = self.statusNone
        }
        
        
        //})
    }
    
    func getNumberArrayAsString(numbers: [Int]) -> String {
        var returnString = ""
        var i = 0
        for number in numbers {
            if i != 0 { returnString.append(" | ") }
            returnString.append(String(number))
            i += 1
        }
        //returnString.append(String(number))
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

class HelperFunctions{
    func shell(launchPath: String, arguments: [String] = []) -> (String? , Int32) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()
        return (output, task.terminationStatus)
    }
}


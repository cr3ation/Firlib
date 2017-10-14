//
//  ViewController.swift
//  Firlib
//
//  Created by Henrik Engström on 2017-10-14.
//

import Cocoa

class ViewController: NSViewController {
    let irlibPath: String = "/Users/henrikengstrom/PycharmProjects/irlib_demo"
    let statusAvailable = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))
    let statusNone = NSImage(named: NSImage.Name(rawValue: "NSStatusNone"))
    
    
    var pickManagers: [PickManager] = []
    var selectedIndex = 0
    
    @IBOutlet weak var h5FileSelector: NSPopUpButton!
    @IBOutlet weak var utmCoordinatesButton: NSButton!
    @IBOutlet weak var cachesButton: NSButton!
    
    // When a new file is selected in drop down
    @IBAction func newFileSelected(_ sender: Any) {
        selectedIndex = h5FileSelector.indexOfSelectedItem
    }

    @IBAction func utmCoordinatesButtonClicked(_ sender: Any) {
        utmCoordinatesButton.isEnabled = false
        pickManagers[selectedIndex].generateUtmFile()
        updateGuiComponents()
    }
    
    @IBAction func cachesButtonClicked(_ sender: Any) {
        let pickManager = pickManagers[selectedIndex]
        cachesButton.isEnabled = false
        pickManager.generateCaches()
        updateGuiComponents()
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialSetup()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // Initial setup
    func initialSetup(){
        let irlibUrl = URL(fileURLWithPath: self.irlibPath)
        let h5FilesUrl = getH5Files()
        h5FileSelector.removeAllItems()
        
        for h5FileUrl in h5FilesUrl{
            let fileName = h5FileUrl.pathComponents.last
            h5FileSelector.addItem(withTitle: fileName!)
            let pickManager = PickManager(h5FileUrl: h5FileUrl, irlibUrl: irlibUrl)
            self.pickManagers.append(pickManager)
        }
        updateGuiComponents()
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
                print(pathComponents[pathComponents.count - 1])
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
    
    // Validate GUI
    func updateGuiComponents()
    {
        let pickManager = pickManagers[selectedIndex]
        
        // Utm coordinates
        if pickManager.utmFileExists {
            utmCoordinatesButton.isEnabled = false
            utmCoordinatesButton.image = statusAvailable
        }
        else {
            utmCoordinatesButton.isEnabled = true
            utmCoordinatesButton.image = statusNone
        }
        
        // Caches
        if pickManager.utmFileExists {
            if pickManager.cacheFilesExist {
                cachesButton.isEnabled = false
                cachesButton.image = statusAvailable
            }
            else {
                cachesButton.isEnabled = true
                cachesButton.image = statusNone
            }
        }
        else {
            cachesButton.isEnabled = false
            cachesButton.image = statusNone
        }
    }
    
    
    // Populate h5 picker
    func populateH5Picker(){
        
    }

}


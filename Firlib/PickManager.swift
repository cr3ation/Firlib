//
//  PickManager.swift
//  Firlib
//
//  Created by Henrik Engström on 2017-10-14.
//

import Foundation

class PickManager {
    // Settings
    let prefix: String
    let pythonPath = "/Users/henrikengstrom/Documents/venv-27/bin/python"
    
    // Temporary - to remove/change/fix
    private let appleScriptUrl: URL
    
    // Public properties
    var h5FileExists: Bool = false
    var utmFileExists: Bool = false
    var cacheFilesExist: Bool = false
    var dumpmetaFileExists: Bool = false
    
    
    // Generated files
    let h5FileUrl: URL
    private let utmFileUrl: URL
    private let cacheFileUrl: URL
    private let dumpmetaFileUrl: URL
    
    // Folders
    private let irlibFolderUrl: URL
    private let cacheFolderUrl: URL
    private let dataFolderUrl: URL
    private let offsetsFolderUrl: URL
    private let pickingFolderUrl: URL
    private let ratingFolderUrl: URL
    
    // Irlib files
    private let h5_add_utmUrl: URL
    private let h5_generate_cachesUrl: URL
    private let h5_dumpmetaUrl: URL
    private let icepick2Url: URL
    private let icerateUrl: URL
    
    init(h5FileUrl: URL, irlibUrl: URL){
        // settings
        let cacheFolderName = "cache"
        let dataFolderName = "data"
        let offsetsFolderName = "offsets"
        let pickingFolderName = "picking"
        let ratingFolderName = "rating"
        
        // Irlib files
        self.h5_add_utmUrl = irlibUrl.appendingPathComponent("h5_add_utm.py")
        self.h5_generate_cachesUrl = irlibUrl.appendingPathComponent("h5_generate_caches.py")
        self.h5_dumpmetaUrl = irlibUrl.appendingPathComponent("h5_dumpmeta.py")
        self.icepick2Url = irlibUrl.appendingPathComponent("icepick2.py")
        self.icerateUrl = irlibUrl.appendingPathComponent("icerate.py")
        
        // Folders
        self.irlibFolderUrl = irlibUrl
        self.cacheFolderUrl = irlibUrl.appendingPathComponent(cacheFolderName)
        self.dataFolderUrl = irlibUrl.appendingPathComponent(dataFolderName)
        self.offsetsFolderUrl = irlibUrl.appendingPathComponent(offsetsFolderName)
        self.pickingFolderUrl = irlibUrl.appendingPathComponent(pickingFolderName)
        self.ratingFolderUrl = irlibUrl.appendingPathComponent(ratingFolderName)
        
        // h5 prefix
        let tmpUrl = h5FileUrl.deletingPathExtension()
        self.prefix = tmpUrl.pathComponents[tmpUrl.pathComponents.count - 1]
        
        // Temp files
        self.appleScriptUrl = irlibUrl.appendingPathComponent("run_in_terminal.scpt")
        
        // Picking files
        self.h5FileUrl = h5FileUrl
        self.utmFileUrl = self.dataFolderUrl.appendingPathComponent(self.prefix + "_utm.h5")
        self.cacheFileUrl = self.cacheFolderUrl.appendingPathComponent(self.prefix + "_utm_line0_0.ird")
        self.dumpmetaFileUrl = self.dataFolderUrl.appendingPathComponent(self.prefix + "_utm_dump.csv")
        
        checkIfFilesExists()
    }
    
    // Helper functions
    func checkIfFilesExists(){
        self.h5FileExists = FileManager.default.fileExists(atPath: self.h5FileUrl.path)
        self.utmFileExists = FileManager.default.fileExists(atPath: self.utmFileUrl.path)
        self.cacheFilesExist = FileManager.default.fileExists(atPath: self.cacheFileUrl.path)
        self.dumpmetaFileExists = FileManager.default.fileExists(atPath: self.dumpmetaFileUrl.path)
    }
    
    // -------------- Call python stuff ------------------
    func generateUtmFile(){
        runPython(arguments: [self.h5_add_utmUrl.path, self.h5FileUrl.path, self.utmFileUrl.path])
        sleep(10)
        self.utmFileExists = true
    }
    
    func generateCaches(){
        runPython(arguments: [self.h5_generate_cachesUrl.path, "-g", "-b", "-r", utmFileUrl.path])
        sleep(20)
        self.cacheFilesExist = true
    }
    
    func openIcepick2(){
        let(_, _) = openShell(launchPath: "/usr/bin/osascript", arguments: [appleScriptUrl.path, irlibFolderUrl.path, pythonPath, icepick2Url.path, utmFileUrl.path])
    }
    
    func openIcerate(){
        let(_, _) = openShell(launchPath: "/usr/bin/osascript", arguments: [appleScriptUrl.path, irlibFolderUrl.path, pythonPath, icerateUrl.path, "-f", utmFileUrl.path])
    }
    // ---------------------------------------------------
    
    
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
    
    func openShell(launchPath: String, arguments: [String]) -> (String? , Int32) {
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
    
    func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
    
    
    
    
    private func runPython(arguments: [String] = []){
        let process = Process()
        process.launchPath = pythonPath
        process.currentDirectoryPath = self.irlibFolderUrl.path
        //process.arguments = ["/Users/henrikengstrom/PycharmProjects/irlib_demo/h5_add_utm.py",
        //                     "/Users/henrikengstrom/PycharmProjects/irlib_demo/data/28-03_skift2-2.h5",
        //                     "/Users/henrikengstrom/PycharmProjects/irlib_demo/data/sallad.h5" ]
        process.arguments = arguments
        process.launch()
    }
}


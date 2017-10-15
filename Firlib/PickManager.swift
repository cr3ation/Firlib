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
    var dumpmetaFileExists: Bool = false
    var utmFileExists: Bool = false
    var cacheFilesExist: Bool = false
    var pickedFilesExist: Bool = false
    var offsetFileExists: Bool = false
    
    var pickedLines: [Int] = []
    var unpickedLines: [Int] = []
    var ratedLines: [Int] = []
    
    // Generated files
    let h5FileUrl: URL
    private let utmFileUrl: URL
    private let dumpmetaFileUrl: URL
    private let offsetFileUrl: URL
    
    var cacheFilesUrls: [URL] = []
    var pickFilesUrls: [URL] = []
    var ratingFilesUrls: [URL] = []
    
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
        self.dumpmetaFileUrl = self.dataFolderUrl.appendingPathComponent(self.prefix + "_utm_metadata.csv")
        self.offsetFileUrl = self.dataFolderUrl.appendingPathComponent(self.prefix + "_utm_offsets.csv")
        self.cacheFilesUrls = getFilesUrls(folder: cacheFolderUrl, nameFilter: self.prefix + "_utm_line")
        self.pickFilesUrls = getFilesUrls(folder: pickingFolderUrl, nameFilter: self.prefix + "_utm_line")
        
        // Others
        self.pickedLines = getLines(folderUrl: self.pickingFolderUrl, nameFilter: self.prefix + "_utm_line")
        self.ratedLines = getLines(folderUrl: self.ratingFolderUrl, nameFilter: self.prefix + "_utm_line")
        
        checkIfFilesExists()
    }
    
    // Helper functions
    func checkIfFilesExists(){
        self.h5FileExists = FileManager.default.fileExists(atPath: self.h5FileUrl.path)
        self.dumpmetaFileExists = FileManager.default.fileExists(atPath: self.dumpmetaFileUrl.path)
        self.utmFileExists = FileManager.default.fileExists(atPath: self.utmFileUrl.path)
        if cacheFilesUrls.count > 0 {
            self.cacheFilesExist = true
        }
        if pickFilesUrls.count > 0 {
            self.pickedFilesExist = true
        }
        self.offsetFileExists = FileManager.default.fileExists(atPath: self.offsetFileUrl.path)
    }
    
    // -------------- Call python stuff ------------------
    func generateMetadata(){
        let(_, _) = openShell(launchPath: "/usr/bin/osascript", arguments: [appleScriptUrl.path, irlibFolderUrl.path, pythonPath, h5_dumpmetaUrl.path, h5FileUrl.path,  ">", dumpmetaFileUrl.path])
    }
    
    func generateUtmFile(){
        runPython(arguments: [self.h5_add_utmUrl.path, self.h5FileUrl.path, self.utmFileUrl.path])
    }
    
    func generateCaches(){
        runPython(arguments: [self.h5_generate_cachesUrl.path, "-g", "-b", "-r", utmFileUrl.path])
        
        self.cacheFilesExist = true
    }
    
    func openIcepick2(){
        let(_, _) = openShell(launchPath: "/usr/bin/osascript", arguments: [appleScriptUrl.path, irlibFolderUrl.path, pythonPath, icepick2Url.path, utmFileUrl.path])
    }
    
    func openIcerate(){
        let(_, _) = openShell(launchPath: "/usr/bin/osascript", arguments: [appleScriptUrl.path, irlibFolderUrl.path, pythonPath, icerateUrl.path, "-f", utmFileUrl.path])
    }
    
    func generateOffsets(){
        if FileManager.default.fileExists(atPath: self.offsetFileUrl.path) == false {
            copyItem(atURL: self.dumpmetaFileUrl, toURL: self.offsetFileUrl)
        }
        let(_, _, _) = runCommand(cmd: "/usr/bin/open", args: self.offsetFileUrl.path)
    }
    
    // ---------------------------------------------------
    
    
    private func shell(launchPath: String, arguments: [String] = []) -> (String? , Int32) {
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
    
    private func openShell(launchPath: String, arguments: [String]) -> (String? , Int32) {
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
    
    private func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
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
    
    private func copyItem(atURL: URL, toURL: URL){
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: atURL, to: toURL)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }

    private func getFiles(folderUrl: URL, fileNameFilter: String) -> [URL]{
        let filesUrl = contentsOf(folder: folderUrl)
        var foundFilesUrl: [URL] = []
        
        // All h5 files, not _utm.h5
        for fileUrl in filesUrl {
            var pathComponents = fileUrl.pathComponents
            
            // Files with matching name filter
            if pathComponents[pathComponents.count - 1].lowercased().range(of: fileNameFilter.lowercased()) != nil {
                foundFilesUrl.append(fileUrl)
            }
        }
        return foundFilesUrl
    }
    
    // Returns all files in folder
    private func contentsOf(folder: URL) -> [URL] {
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
    
    private func getFilesUrls(folder: URL, nameFilter: String) -> [URL] {
        return getFiles(folderUrl: folder, fileNameFilter: nameFilter)
    }
    
    private func getLines(folderUrl: URL, nameFilter: String) -> [Int] {
        let pickedFilesUrls = getFilesUrls(folder: folderUrl, nameFilter: nameFilter)
        var pickedFileNumbers: [Int] = []
        
        for pickedFileUrl in pickedFilesUrls {
            var pickFileName = pickedFileUrl.lastPathComponent
            pickFileName.removeLast(4)
            let stringLength = pickFileName.count
            pickFileName.removeFirst(stringLength - 1)
            pickedFileNumbers.append(Int(pickFileName)!)
        }
        pickedFileNumbers.sort()
        return pickedFileNumbers
    }
}


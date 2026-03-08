
// #if macOS TODO: RETRIGGER THIS IF ENDIF BLOCK BEFORE EXPORT TO IOS

import Foundation
import AppKit
import SwiftData
import PDFKit
// TODO: NSImage is for MacOS, UIImage is for IOS



class MusicScanner {
    

    
    var inputDir : [URL] = []
    var sheetMusicName : String = ""
    var xmlPaths : [URL] = []
    
    var outputDir : URL? {
        var out : URL
        do { try out = FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) }
        catch {
            print("Error finding documents directory: \(error)")
            return nil
        }
        return out.appendingPathComponent("Piano-Assistant/AudiverisOutput")
    }
    
    var documentsDir : URL? { // by default will be app folder in Documents
        var out : URL
        do { try out = FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) }
        catch {
            print("Error finding documents directory: \(error)")
            return nil
        }
        return out.appendingPathComponent("Piano-Assistant/Songs")
    }
    
    func checkScanErrors(items : [Item], songName : String) -> Int {
        for i in items {
            if i.title == songName {
                return 2
            }
        }
        
        if songName == "" {
            return 1
        }
        else if !isAlphanumeric(string: songName) {
            return 3
        }
        
        return 0
    }
    
    
    

    func isAlphanumeric(string: String) -> Bool {
        return (string.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil)
    }
    
    // function to receive an input path, checks not needed since path to be found via file viewer window
    func setInputPath() async {
        await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.title = "Select Music Sheet"
            panel.message = "Select the files in order they should be scanned. Select page #1 first, then #2, etc."
            panel.prompt = "Choose"
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = true
            panel.canCreateDirectories = true
            
            panel.begin { response in
                if response == .OK {
                    self.inputDir = panel.urls // Files are returned in order they are selected
                    self.sheetMusicName = panel.url!.deletingPathExtension().lastPathComponent
                }
                continuation.resume()
            }
        }
    }
    
    func setXmlPath() async {
        await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.title = "Select the XML File"
            panel.message = "Choose the file that will be parsed."
            panel.prompt = "Choose"
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false
            
            panel.begin { response in
                if response == .OK {
                    for url in panel.urls {
                        self.xmlPaths.append(url)
                    }
                    print(self.xmlPaths)
                }
                continuation.resume()
            }
        }
    }
    
    func copyFiles(sourceURLs: [URL], dirName: String) -> [URL] {
        
        if sourceURLs.isEmpty { return [] }
        guard let documentsDir = documentsDir else {
            print("DOCUMENTS DIRECTORY IS NULL!")
            return []
        }
        
        let fileManager = FileManager.default
        var filePaths : [URL] = []
        
        let destinationURL = documentsDir.appendingPathComponent("\(dirName)")
        
        do {
            // Check if the destination directory exists, create it if not
            if !fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            for url in sourceURLs {
                let fileOut = URL(string: String(describing: destinationURL) + "/" + url.lastPathComponent.split(separator: " ").joined())!
                filePaths.append(fileOut)
                try fileManager.copyItem(at: url, to: fileOut)
            }
        } catch {
            print("An error occured while copying files \(error)")
        }
        return filePaths
    }
    
    public func PDFtoPNG(pdf: URL) -> [URL] {

        let outputURL = pdf.deletingLastPathComponent().deletingPathExtension()
        let fileName = outputURL.deletingPathExtension().lastPathComponent
        var images : [URL] = []
        
        
        
        // Convert the PDF to PNGs that are stored at that same directory, then return an array of URLs to each image

        guard let pdfDocument = PDFDocument(url: pdf) else {
            print("Failed to load PDF")
            return []
        }
        
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }

            let rect = page.bounds(for: .mediaBox)
            // Audiveris calculates cordinates off of given dimensions, changing means propagating the change everywhere
            let scale = getMaxAudiverisScale(height: rect.height, width: rect.width);
            let width = Int(rect.width * scale)
            let height = Int(rect.height * scale)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )!

            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.scaleBy(x: scale, y: scale)

            page.draw(with: .mediaBox, to: context)

            guard let cgImage = context.makeImage() else { continue }

            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            let pngData = bitmap.representation(using: .png, properties: [:])!

            let outputURL = outputURL.appendingPathComponent("\(fileName)\(i + 1).png");
            
            do { try pngData.write(to: outputURL) } catch { print("Error writing file data"); continue; }
            images.append(outputURL)
            
            }

        
        return images
    }
    
    
    public func clearOutputFolder() {
        let fileManager = FileManager.default
        let files : [String] = (try? fileManager.contentsOfDirectory(atPath: outputDir!.path)) ?? []
        
        for file in files {
            do {
                print(file)
                try fileManager.removeItem(at: URL(filePath: outputDir!.path + "/" + file))
            } catch { print("Error in deleting Item's files") }
        }
        
    }
    
    // function to use Command Line Interface to interact with Audiveris
    // Wont work in Sandbox tests because Audiveris gets flagged by Xcode
    func runAudiveris(item: Item) -> [URL] {
        
        let audiverisPath = "/Applications/Audiveris.app/Contents/MacOS/audiveris"
        
        let process = Process()
        process.executableURL = URL(filePath: audiverisPath)
        
        // Enabling implicitTuplets fixed a problem where tuplets weren't recognized, the longer beat count made
        // the ending notes too long for the measure, and excluded them from the XML
        process.arguments = [
            "-batch",
            "-constant",
            "implicitTuplets=true",
            "-transcribe",
            "-output", outputDir!.path,
        ]
        
        for path in inputDir {
            process.arguments!.append(String(describing: path))
        }

        do {
            try process.run()
        } catch {
            print("Failed to start Audiveris:", error)
            exit(1)
        }

        process.waitUntilExit()
        print("Audiveris exited with code:", process.terminationStatus)
        
        var arr : [URL] = []
        
        // Each file SHOULD have an xml file. If not it will get caught in parseXML
        for file in item.filePath {
            
            let fileName = String(file.deletingPathExtension().lastPathComponent)
            
            arr.append(URL(filePath: outputDir!.path + "/" + fileName + ".xml"))
        }
        
        return arr

    }
    
    func testXMLFiles(item: Item) -> [URL] {
        var arr : [URL] = []
        
        // Each file SHOULD have an xml file. If not something went wrong
        for file in item.filePath {
            
            let fileName = String(file.deletingPathExtension().lastPathComponent)
            
            arr.append(URL(filePath: outputDir!.path + "/" + fileName + ".xml"))
        }
        
        return arr

    }
    
    func getCombinedSong(item: Item) -> [Chord] {
        
        var parsedChords : [Chord] = []
        var errorPages : [URL] = []
        var repeatNum : Int = 0
        
        for i in 0..<xmlPaths.count {
            let image = item.filePath[i]
            let scales : [CGFloat];
            
            if item.filePath[i].pathExtension == "pdf" {
                scales = getPDFScales(pdf: item.filePath[i])
            } else {
                scales = getImageScale(image: item.filePath[i]) // This deals in points (?)
            }
            
            let beforeParse : Int = parsedChords.count
            parseXML(xmlURL: xmlPaths[i], imagePath : image, repeatChord: &repeatNum, songArray: &parsedChords, scales: scales)
            
            // If no chords were added over an entire file, something went wrong and skip that image
            if beforeParse == parsedChords.count {
                errorPages.append(image)
                continue
            }
            
            if i != xmlPaths.count-1 {
                let breakNote = Note(id: 0, midi: -1, note: "BREAK", accidental: "!", octave: -1, posX: 0, posY: 0, measureMidY: 0)
                let pageBreak = Chord(notes: [breakNote], order: parsedChords.count)
                parsedChords.append(pageBreak)
            }
            
        }
        
        for error in errorPages {
            item.filePath.remove(at: item.filePath.firstIndex(of: error)!)
        }
        print("Finished parsing, \(parsedChords.count)")
        return parsedChords
    }
    
    // TODO: function to write a text file with the ordered notes and details for easy transport & light storage
    
    // Function to parse xml for data (notes, positions, etc.)
    func parseXML(xmlURL : URL, imagePath : URL, repeatChord : inout Int, songArray: inout [Chord], scales: [CGFloat]) {
        
        // Values are set as an offset in steps from the first key in its octave
        let letterConv : [String : Double] = ["C":0, "D":2, "E":4, "F":5, "G":7, "A":9, "B":11, "error": -1]
        
        var scaleCur : Int = 0;
        
        guard let xml = try? XMLDocument(contentsOf: xmlURL)
        else {
            print("Error loading XML")
            return
        }
        
        guard let partNodes = try? xml.nodes(forXPath: "//part")
        else {
            print("Error finding part nodes")
            return
        }
    
        let pageHeight = Double(
            try! xml.nodes(forXPath: "//defaults/page-layout/page-height")
                .first?
                .stringValue ?? "1500"
        
        )
        let pageTopMargin = Double(
            try! xml.nodes(forXPath: "//defaults/page-layout/page-margins/top-margin")
                .first?
                .stringValue ?? "80"
        )
        let pageBotMargin = Double(
            try! xml.nodes(forXPath: "//defaults/page-layout/page-margins/bottom-margin")
                .first?
                .stringValue
            ?? "80"
        )
        
        var staffDistances : [Double] = [-1,0,0]
        var cleffKey : [Int: String] = [0:"0",1:"0",2:"0"]
        var measureSysTop : Double = 0
        
        print(imagePath)
        let sheet = NSImage(contentsOf: imagePath)!
    
        
        // pageHeight is in tenths
        let tenthsToPixels = sheet.size.height / (pageHeight! - pageBotMargin! - pageTopMargin!)
        
        var distance : Double = 66
        
        for part in partNodes {

            guard let measureNodes = try? part.nodes(forXPath: "measure")
            else {
                print("Error finding measure nodes")
                return
            }
            
            var measureOffset : Double = 0
            
            var measureRepeatBar = false
            
            for measure in measureNodes {


                // Create a dictionary of node arrays to partition nodes via x value
                // nodes are only put in the dictionary for their measure, so seperation for chords is already done
                var nodeDictionary : [Double: [Note]] = [:]

                let newPage = 
                    try! measure.nodes(forXPath: "print/@new-page")
                    .first?
                    .stringValue ?? ""
                
                let newSystem = 
                    try! measure.nodes(forXPath: "print/@new-system")
                    .first?
                    .stringValue ?? "no"
                
                let measureWidth = Double(
                    try! measure.nodes(forXPath: "@width")
                        .first?
                        .stringValue ?? "0"
                )
                
                // Only PDFs could reasonably have this but they are split into pages and parsed separately so this should only run if something funky is happening
                if newPage == "yes" { // Reset staff values if a new page is hit
                    
                    for i in 0..<staffDistances.count {
                        staffDistances[i] = 0;
                    }
                    
                    // Add a Page Break chord, something that CANNOT be a note to indicate a new page
                    let breakNote = Note(
                        id: 0,
                        midi: -1,
                        note: "BREAK",
                        accidental: "!",
                        octave: -1,
                        posX: 0,
                        posY: 0,
                        measureMidY: 0
                    )
                    
                    let pageBreak = Chord(notes: [breakNote], order: songArray.count)
                    songArray.append(pageBreak)
                    
                    scaleCur+=1
                    
                }
                
                // Top System distance is ONLY for the top most measure
                let topSystemDistance = Double(
                    try! measure.nodes(forXPath: "print/system-layout/top-system-distance")
                        .first?
                        .stringValue ?? "0"
                )
                
                if topSystemDistance != 0 { measureSysTop = topSystemDistance! }
                
                // system-distance is the distance between two lines of measures; the big empty space
                let measureSysDist = Double (
                    try! measure.nodes(forXPath: "print/system-layout/system-distance")
                        .first?
                        .stringValue ?? "0"
                )
                
                // left margin of the measures
                let leftMargin = Double(
                    try! measure.nodes(forXPath: "print/system-layout/system-margins/left-margin")
                        .first?
                        .stringValue ?? "0"
                )
                
                // staff-distance is the distance between two staves
                distance = Double(try! measure.nodes(forXPath: "print/staff-layout/staff-distance").first?.stringValue ?? String(distance))!
                
                
                if measure == measureNodes.first! {
                    for i in 0..<staffDistances.count {
                        // 0 gets negative distance, but thats ok since staff #s are always >=1
                        // Add the top part of page, and then the distance of a staff and the distance between staffs for every staff besides the first
                        // The Y coordinate of the staff is the top of its staff lines
                        staffDistances[i] = measureSysTop + ((40 + distance) * Double(i-1))
                    }

                }
                
                if newSystem == "yes" {
                    
                    measureOffset = 0
                    for i in 0..<staffDistances.count {
                        
                        staffDistances[i] += 80 + measureSysDist! + distance
                    }

                }
                
                let measureMid = CGFloat(staffDistances[1] + 40 + distance/2) * tenthsToPixels

                // TODO: IMPLEMENT OR DOUBLE CHECK SUPPORT FOR MORE THAN 2 STAVES

                
                // rests will continue loop, as they are considered <note> nodes
                for child in measure.children ?? [] {
                    
                    if child.name == "note" {
                        
                        let note = child as! XMLElement
                        
                        guard let noteLetter =
                                try! note.nodes(forXPath: "pitch/step")
                            .first?
                            .stringValue
                        else { continue }
                        
                        guard let noteStep =
                                letterConv[noteLetter]
                        else { continue }
                        
                        guard let noteOctave =
                                Double(
                                    try! note.nodes(forXPath: "pitch/octave")
                                        .first?
                                        .stringValue ?? "-1"
                                )
                        else { continue }
                        
                        guard let noteXTenths = Double(
                            try! note.nodes(forXPath: "@default-x")
                                .first?
                                .stringValue ?? "-1"
                        ) else { continue }
                        
                        let noteAlter = Double(
                            try! note.nodes(forXPath: "pitch/alter")
                                .first?.stringValue ?? "0"
                        )
                        
                        let noteStaff = Int(
                            try! note.nodes(forXPath: "staff")
                                .first?
                                .stringValue ?? "1"
                        )
                        
                        let noteValue = (noteOctave + 1) * 12 + (noteStep + noteAlter!)
                        
                        // Calculate absolute Y in MusicXML tenths
                        var noteY : Double = 0
                        var noteX : Double = 0
                        // Octaves are C -> C, Top of treble clef measure is an F, top of bass clef is A
                        let trebleOrder : [String : Double] = ["C":-3,"D":-2,"E":-1,"F":0,"G":1,"A":2,"B":3]
                        let bassOrder : [String : Double] = ["C":-5,"D":-4,"E":-3,"F":-2,"G":-1,"A":0,"B":1]
                        var staffStep : Double = 0
                        
                        // 7 notes in an octave, 5 tenths per step
                        // 5 and 3 come from the octave of the top note in that staff.
                        // Top of treble cleff is F5, top of bass cleff is A3
                        // Bigger Y = lower on page, subtract based off top to get offset for below
                        if cleffKey[noteStaff!] == "G" { // Treble cleff
                            
                            staffStep = ((5 - noteOctave) * 35) - ((trebleOrder[noteLetter]!) * 5)
                        }
                        if cleffKey[noteStaff!] == "F" { // Bass cleff
                            staffStep = ((3 - noteOctave) * 35) - ((bassOrder[noteLetter]!) * 5)
                        }
                        
                        // All MusicXML measurements in X or page heights are in Tenths
                        // Tenths are one tenth the size of the space between staff lines
                        // measureOffset offsets for the x ranges of the previous measure(s)
                        // noteXTenths is the left edge of the note, add 5 tenths to get the center
                        noteX = (noteXTenths + leftMargin! + measureOffset + 5) * tenthsToPixels * scales[scaleCur]
                        noteY = (staffDistances[noteStaff!] + staffStep) * tenthsToPixels * scales[scaleCur]
                        
                        let noteId : Int = Int(noteX * noteY)
                        let alterConv = [-2: "bb", -1: "b", 0: "", 1: "#", 2: "x"]
                        
                        let noteNode = Note(
                            id: noteId,
                            midi: Int(noteValue),
                            note: noteLetter,
                            accidental: alterConv[Int(noteAlter!)]!,
                            octave: Int(noteOctave),
                            posX: noteX,
                            posY: noteY,
                            measureMidY: measureMid
                        )
                        
                        
                        if !nodeDictionary.keys.contains(noteXTenths) {
                            nodeDictionary.updateValue([noteNode], forKey: noteXTenths)
                        } else {
                            guard var a = nodeDictionary[noteXTenths] else { continue }
                            a.append(noteNode)
                            nodeDictionary[noteXTenths] = a
                        }
                        
                    }
                    
                    else if child.name == "attributes" {
                        
                        guard let clefs = try? child.nodes(forXPath: "clef") else { continue }
                        
                        for clef in clefs {
                            
                            guard let number = Int(
                                try! clef.nodes(forXPath: "@number")
                                    .first?
                                    .stringValue ?? "1"
                                )
                            else { continue }
                            
                            guard let sign =
                                try? clef.nodes(forXPath: "sign")
                                    .first?
                                    .stringValue
                            else { continue }
                            
                            cleffKey[number] = sign
                            
                        }
                        continue
                    }
                    
                    else if child.name == "barline" {
                        
                        let direction = try? child.nodes(forXPath: "repeat/@direction").first?.stringValue
                        if direction == "forward" {
                            repeatChord = songArray.count
                        }
                        else if direction == "backward" {
                            measureRepeatBar = true // Can only process repeat after all notes inserted
                        }

                        continue
                        
                    }
                    // for measure.children scope
                    
                }
                let sortedKeys = nodeDictionary.keys.sorted() // sort keys in dictionary
                
                if sortedKeys.isEmpty { continue }
                
                var chordArray : [Note] = [] // create a placeholder array for chord notes
                chordArray.append(contentsOf: nodeDictionary[sortedKeys[0]]!) // append the first notes via sorted keys
                
                if sortedKeys.count == 1 {
                    songArray.append(Chord(notes: chordArray, order: songArray.count))

                } else {
                    
                    for index in 1...sortedKeys.count - 1 {
                        // if the current and previous key (x value of note) is within 7 tenths, add current to the chord
                        if abs(sortedKeys[index] - sortedKeys[index - 1]) < 7 {
                            chordArray.append(contentsOf: nodeDictionary[sortedKeys[index]]!)
                        }
                        else { // else add the current chord to songArray, clear chordArray, start a new chord with current
                            songArray.append(Chord(notes: chordArray, order: songArray.count))
                            chordArray = []
                            chordArray.append(contentsOf: nodeDictionary[sortedKeys[index]]!)
                            if (index == sortedKeys.count-1) {
                                songArray.append(Chord(notes: chordArray, order: songArray.count))
                            }
                        }
                    }
                }
                
                // measure scope
                
                
                if measureRepeatBar {
                    var duplicatedChords : [Chord] = []
                    var repeatOverPages : Int = 0;
                    
                    for i in repeatChord..<songArray.count {
                        let duplicate = songArray[i].copy()
                        duplicatedChords.append(duplicate)
    
                        // If a BREAK note is copied, BACK notes have to be added at the end so pages go back
                        if songArray[i].notes.first!.note == "BREAK" { repeatOverPages += 1 }
                    }
                    for _ in 0..<repeatOverPages {
                        let backNote = Note(id: 0, midi: -1, note: "BACK", accidental: "!", octave: -1, posX: 0, posY: 0, measureMidY: 0)
                        songArray.append(Chord(notes: [backNote], order: songArray.count))
                    }
                    for i in 0..<duplicatedChords.count {
                        duplicatedChords[i].order = songArray.count
                        songArray.append(duplicatedChords[i])
                    }
                    
                    measureRepeatBar = false
                    repeatChord = 0
                    
                }
                measureOffset = measureOffset + measureWidth! + leftMargin!
                
            }
            // part scope
        }
        // after all for loops
        
    }
    
    func getPDFScales(pdf: URL) -> [CGFloat] {
        var scales : [CGFloat] = [];
        
        guard let pdfDocument = PDFDocument(url: pdf) else {
            print("Failed to load PDF")
            return []
        }
        
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let rect = page.bounds(for: .mediaBox)
            let area = rect.width * rect.height
            let scale : CGFloat = getMaxAudiverisScale(height: rect.height, width: rect.width)
            scales.append(scale)
            
        }
        return scales
    }
    
    func getImageScale(image: URL) -> [CGFloat] {
        let image = NSImage(contentsOfFile: image.path)!
        let area = image.size.width * image.size.height;
        let scales : [CGFloat] = [getMaxAudiverisScale(height: image.size.height, width: image.size.width)]
        return scales
    }
    
    func getMaxAudiverisScale(height: CGFloat, width: CGFloat) -> CGFloat {
        let area = height * width
        return CGFloat(20000000/area)
    }
    
    func scan(item: Item, onlyPNG : Bool = false, customImport : Bool = false) async {
        
        // Prompts the user to select the files
        await setInputPath()
        
        if (item.title!.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil) {
            print("what the frick")
        }
        
        item.filePath = copyFiles(sourceURLs: inputDir, dirName: item.title!)

        
        
        if customImport {
            await setXmlPath()
        } else {
            
            // Run audiveris on the urls stored in inputDir, populates xmlPaths with XML files
            //xmlPaths = runAudiveris(item: item)
            xmlPaths = testXMLFiles(item: item) // Use this function to get XML paths in sandbox since Audiveris cant run
        }
        
        
        // Run parseXML for each XML file inserted and insert pageBreak notes after every file
        item.songArray = getCombinedSong(item: item)
        
        for file in item.filePath {
            if file.pathExtension == "pdf" {
                let images = PDFtoPNG(pdf: file)
                // Rearrange item.filePath to replace the PDF with the converted PNGs IN ORDER
                let index = item.filePath.firstIndex(of: file)!
                for i in 0..<images.count {
                    item.filePath.insert(images[i], at: index + i)
                }
            }
        }

        if (onlyPNG) { return }
        
        
        // After parsing is completed, clear out the no longer needed xml files in local files
        //clearOutputFolder()
        
        
    }
    
    // functino to transfer the file via airdrop
    
}


// #endif

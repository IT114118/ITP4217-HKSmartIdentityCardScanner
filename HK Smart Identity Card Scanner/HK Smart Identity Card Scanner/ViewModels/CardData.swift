//
//  CardData.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 5/4/2021.
//

import SwiftUI
import Foundation
import Vision

class CardData: ObservableObject {
    @Published var isEnglishRecognizing: Bool = false
    @Published var isChineseRecognizing: Bool = false
    @Published var isFaceRecognizing: Bool = false
    
    @Published var chineseName: String?
    @Published var englishName: String?
    @Published var dateOfBirth: String?
    @Published var dateOfIssue: String?
    @Published var dateOfRegistration: String?
    @Published var sex: String?
    @Published var ccc: [Int] = [Int]()
    @Published var cccString: String?
    @Published var symbols: String?
    @Published var number: String?
    @Published var face: UIImage?
    @Published var source: UIImage?
    
    private var cccStringTemp: String?
    
    func reset() {
        self.isEnglishRecognizing = false
        self.isChineseRecognizing = false
        self.isFaceRecognizing = false
        self.chineseName = nil
        self.englishName = nil
        self.dateOfBirth = nil
        self.dateOfIssue = nil
        self.dateOfRegistration = nil
        self.sex = nil
        self.ccc = [Int]()
        self.cccString = nil
        self.symbols = nil
        self.number = nil
        self.cccStringTemp = nil
    }
    
    func isAllowSave() -> Bool {
        if self.isRecognizing()
        || self.englishName == nil || self.englishName!.isEmptyOrWhitespace()
        || self.dateOfBirth == nil || self.dateOfBirth!.isEmptyOrWhitespace()
        || self.dateOfIssue == nil || self.dateOfIssue!.isEmptyOrWhitespace()
        || self.dateOfRegistration == nil || self.dateOfRegistration!.isEmptyOrWhitespace()
        || self.sex == nil || self.sex!.isEmptyOrWhitespace()
        || self.symbols == nil || self.symbols!.isEmptyOrWhitespace()
        || self.number == nil || self.number!.isEmptyOrWhitespace() {
            return false
        }
        
        return true
    }
    
    func isRecognizing() -> Bool {
        return self.isEnglishRecognizing || self.isChineseRecognizing || self.isFaceRecognizing
    }
    
    func recognize(in uiImage: UIImage) {
        self.source = uiImage
        self.face = uiImage
        self.isEnglishRecognizing = true
        self.isChineseRecognizing = true
        self.isFaceRecognizing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
        
            let handler = VNImageRequestHandler(cgImage: self.source!.cgImage!, options: [:])
            do {
                try handler.perform([self.englishTextRecognitionRequest, self.chineseTextRecognitionRequest, self.faceDetectionRequest])
            } catch {
                //self.delegate?.didFailRecognizeTextFromImage()
            }
        }
    }
    
    /*
    func printResult() {
        print("self.chineseName \(self.chineseName)")
        print("self.englishName \(self.englishName)")
        print("self.dateOfBirth \(self.dateOfBirth)")
        print("self.dateofIssue \(self.dateOfIssue)")
        print("self.dateofRegistration \(self.dateOfRegistration)")
        print("self.sex \(self.sex)")
        print("self.ccc \(self.ccc)")
        print("self.symbols \(self.symbols)")
        print("self.number \(self.number)")
    }*/
    
    private var englishTextRecognitionRequest: VNRecognizeTextRequest {
        let v = VNRecognizeTextRequest(completionHandler: { [weak self] (request, error) in
            if let recognizedText = request.results as? [VNRecognizedTextObservation] {
                let transcript = recognizedText.reduce("") { result, observation in
                    guard let candidate = observation.topCandidates(1).first?.string else { return "" }
                    return result.appending(candidate) + "\n"
                }
                
                DispatchQueue.main.async { [weak self] in
                    let lines = transcript.split(whereSeparator: \.isNewline)
                    for line in lines { self?.storeEnglish(String(line)) }
                    self?.isEnglishRecognizing = false
                }
            }
        })
        v.recognitionLevel = .accurate
        v.usesLanguageCorrection = false
        v.recognitionLanguages = ["en_GB"]
        
        return v
    }
    
    private var chineseTextRecognitionRequest: VNRecognizeTextRequest {
        let v = VNRecognizeTextRequest(completionHandler: { [weak self] (request, error) in
            if let recognizedText = request.results as? [VNRecognizedTextObservation] {
                let transcript = recognizedText.reduce("") { result, observation in
                    guard let candidate = observation.topCandidates(1).first?.string else { return "" }
                    return result.appending(candidate) + "\n"
                }
                
                DispatchQueue.main.async { [weak self] in
                    let lines = transcript.split(whereSeparator: \.isNewline)
                    for line in lines { self?.storeChinese(String(line)) }
                    self?.isChineseRecognizing = false
                }
            }
        })
        v.recognitionLevel = .accurate
        v.usesLanguageCorrection = false
        v.recognitionLanguages = ["zh-Hant"]
        
        return v
    }
    
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest {
        let v = VNDetectFaceRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                    print("did detect \(results.count) face(s)")
                    
                    let originalFace: UIImage = self.face!
                    var oldBoundingBox: CGRect? = nil
                    
                    for result in results {
                        let boundingBox: CGRect = result.boundingBox
                        
                        if oldBoundingBox == nil || oldBoundingBox!.width < boundingBox.width {
                            oldBoundingBox = boundingBox
                            
                            let size = CGSize(
                                width: boundingBox.width * originalFace.size.width * 1.5,
                                height: boundingBox.height * originalFace.size.height * 1.5
                            )
                            
                            // Adjust the detected boundbox to left a bit due to size * 1.5
                            let xDiff = size.width / 6.0 // Simplified from (size.width - (size.width / 1.5)) / 2.0
                            
                            let origin = CGPoint(
                                x: boundingBox.minX * originalFace.size.width - xDiff,
                                y: (1 - boundingBox.minY) * originalFace.size.height - size.height
                            )
                            
                            // Create rect
                            let rect = CGRect(origin: origin, size: size)
                            
                            // Create bitmap image from context using the rect
                            let imageRef: CGImage = originalFace.cgImage!.cropping(to: rect)!

                            // Create a new image based on the imageRef and rotate back to the original orientation
                            self.face = UIImage(cgImage: imageRef, scale: originalFace.scale, orientation: originalFace.imageOrientation)
                        }
                    }
                } else {
                    print("did not detect any face")
                }
                
                self.isFaceRecognizing = false
            }
        })
        
        return v
    }
    
    private func storeEnglish(_ data: String) {
        if self.englishName == nil, let englishName = data.matchingStrings(regex: "[a-zA-Z\\s]{1,}\\,[a-zA-Z\\s]{1,}").first?[0] {
            self.englishName = englishName
            print("self.englishName \(self.englishName!)")
        } else if self.ccc == [Int](), let cccString = data.matchingStrings(regex: "[0-9\\s]{4,}").first?[0], cccString.count > 4 && cccString[String.Index(utf16Offset: 4, in: cccString)] == " " {
            self.ccc = [Int]()
            self.cccString = ""
            self.chineseName = ""
            
            let subs = cccString.split(separator: " ")
            for sub in subs {
                self.ccc.append(Int(sub)!)
                self.cccString? += sub + " "
                self.chineseName? += ChineseCommercialCodeService.convertToText(String(sub))
            }
            
            self.cccString = self.cccString?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("self.cccString \(self.cccString!)")
            print("self.chineseName \(self.chineseName!)")
        } else if self.dateOfBirth == nil, let dateOfBirth = data.matchingStrings(regex: "[0-9\\s]{2,}-[0-9\\s]{2,}-[0-9]{4,}").first?[0] {
            self.dateOfBirth = dateOfBirth.removingWhitespaces()
            print("self.dateOfBirth \(self.dateOfBirth!)")
            
            if data.contains("F") {
                self.sex = "F"
                print("self.sex \(self.sex!)")
            } else if data.contains("M") {
                self.sex = "M"
                print("self.sex \(self.sex!)")
            }
        } else if self.dateOfIssue == nil, let dateofIssue = data.matchingStrings(regex: "\\([0-9]{1,}\\-[0-9]{1,}\\)").first?[0] {
            self.dateOfIssue = dateofIssue
            print("self.dateofIssue \(self.dateOfIssue!)")
        } else if self.dateOfRegistration == nil, let dateofRegistration = data.matchingStrings(regex: "[0-9\\s]{2,}-[0-9\\s]{2,}-[0-9\\s]{2}").first?[0] {
            self.dateOfRegistration = dateofRegistration.removingWhitespaces()
            print("self.dateofRegistration \(self.dateOfRegistration!)")
            
            if let number = data.matchingStrings(regex: "[A-Z0-9]{7}\\s{0,1}.[A-E0-9]\\)").first?[0] {
                var number = number.removingWhitespaces()
                if number.first! == "7" { number = "Z" + number.dropFirst() }
                self.number = number
                print("self.number \(self.number!)")
            }
        } else if let number = data.matchingStrings(regex: "[A-Z0-9]{7}\\s{0,1}.[A-E0-9]\\)").first?[0] {
            var number = number.removingWhitespaces()
            if number.first! == "7" { number = "Z" + number.dropFirst() }
            self.number = number
            print("self.number \(self.number!)")
        } else if data.matchingStrings(regex: "\\*").first?[0] == "*" {
            var data = data
            if data.last! == "7" { data = data.dropLast() + "Z" }
            self.symbols = data.replacingOccurrences(of: "•", with: "*")
            print("self.symbols \(self.symbols!)")
        }
        
        if self.dateOfBirth != nil && self.englishName != nil && self.sex == nil {
            if data.contains("F") {
                self.sex = "F"
                print("self.sex \(self.sex!)")
            } else if data.contains("M") {
                self.sex = "M"
                print("self.sex \(self.sex!)")
            }
        }
    }
    
    private func storeChinese(_ data: String) {
        if let cccString = data.matchingStrings(regex: "[0-9]{4}").first?[0] {
            self.cccStringTemp = cccString
        }
        
        if self.cccStringTemp != nil && self.sex == nil {
            if data.contains("女") {
                self.sex = "F"
                print("self.sex \(self.sex!)")
            } else if data.contains("男") {
                self.sex = "M"
                print("self.sex \(self.sex!)")
            }
        }
    }
}

extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }
    
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
    func isEmptyOrWhitespace() -> Bool {
        if self.isEmpty { return true }
        return (self.trimmingCharacters(in: .whitespaces) == "")
    }
}

//
//  CardData.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 5/4/2021.
//

import SwiftUI
import Foundation
import Vision

class CardViewModel: ObservableObject {
    // Recognize state
    @Published var isEnglishRecognizing: Bool = false
    @Published var isChineseRecognizing: Bool = false
    @Published var isFaceRecognizing: Bool = false
    @Published var isCardRecognizing: Bool = false
    
    // HKID card information
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
    
    // HKID card images
    @Published var face: UIImage?
    @Published var masked: UIImage?
    @Published var source: UIImage?
    
    // Card Classifier
    @Published var cardModel: Int16?
    @Published var showAlert: Bool = false
    
    enum HKIDCardModel: Int16 {
        case unknown = 0
        case new = 1
        case old = 2
    }
    
    private var cccStringTemp: String?
    
    func reset() {
        self.isEnglishRecognizing = false
        self.isChineseRecognizing = false
        self.isFaceRecognizing = false
        self.isCardRecognizing = false
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
        self.face = nil
        self.masked = nil
        self.source = nil
        self.cardModel = nil
        self.showAlert = false
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
        return self.isEnglishRecognizing || self.isChineseRecognizing || self.isFaceRecognizing || self.isCardRecognizing
    }
    
    func recognize(in uiImage: UIImage) {
        self.reset()
        
        self.source = uiImage
        self.masked = uiImage
        self.isEnglishRecognizing = true
        self.isChineseRecognizing = true
        self.isFaceRecognizing = true
        self.isCardRecognizing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
        
            let handler = VNImageRequestHandler(cgImage: self.source!.cgImage!, options: [:])
            do {
                try handler.perform([
                    self.englishTextRecognitionRequest,
                    self.chineseTextRecognitionRequest,
                    self.faceDetectionRequest,
                    self.cardClassifierRequest,
                ])
            } catch {
                //self.delegate?.didFailRecognizeTextFromImage()
            }
        }
    }
    
    private func getBoundingBox(candidate: VNRecognizedText) -> CGRect {
        // Find the bounding-box observation for the string range.
        let stringRange = candidate.string.startIndex..<candidate.string.endIndex
        let boxObservation = try? candidate.boundingBox(for: stringRange)
        
        let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let boundingBox = boxObservation?.boundingBox.applying(bottomToTopTransform) ?? .zero
        
        return boundingBox
    }
    
    private func getNormalizedRect(boundingBox: CGRect) -> CGRect {
        return VNImageRectForNormalizedRect(boundingBox, Int(self.source!.size.width), Int(self.source!.size.height))
    }
    
    private func isSmallNumberField(_ candidate: VNRecognizedText) -> CGRect? {
        let boundingBox = self.getBoundingBox(candidate: candidate)
        
        // Sample data
        // (0.6903891245524089, 0.20507568713055546, 0.06681811014811201, 0.025795702902686513)
        // (0.7024600505828857, 0.20534820076804494, 0.08781898021697998, 0.029692475900710003)
        // (0.6950006996713034, 0.20937012135982513, 0.08726590784584598, 0.033698290586471560)
        
        if 0.65 < boundingBox.minX && boundingBox.minX < 0.75
            && 0.15 < boundingBox.minY && boundingBox.minY < 0.25
            && 0.01 < boundingBox.width && boundingBox.width < 0.12
            && 0.02 < boundingBox.height && boundingBox.height < 0.05 {
            return self.getNormalizedRect(boundingBox: self.getBoundingBox(candidate: candidate))
        }
        
        return nil
    }
    
    private var englishTextRecognitionRequest: VNRecognizeTextRequest {
        let v = VNRecognizeTextRequest(completionHandler: { [weak self] (request, error) in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    
                    DispatchQueue.main.async { [weak self] in
                        if let rect = self?.storeEnglish(candidate) {
                            if let normalizedRect = self?.getNormalizedRect(boundingBox: rect) {
                                self?.masked = self?.masked!.drawRectangleOnImage(rect: normalizedRect)
                            }
                        } else if let normalizedRect = self?.isSmallNumberField(candidate) {
                            self?.masked = self?.masked!.drawRectangleOnImage(rect: normalizedRect)
                        }
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
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
    
    private var cardClassifierRequest: VNCoreMLRequest {
        let classifier: HKIDCardClassifier = {
            do {
                let config = MLModelConfiguration()
                return try HKIDCardClassifier(configuration: config)
            } catch {
                print(error)
                fatalError("Couldn't create HKIDCardClassifier")
            }
        }()
        
        let model = try! VNCoreMLModel(for: classifier.model)

        let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
            if let results = request.results as? [VNClassificationObservation] {
                DispatchQueue.main.async { [weak self] in
                    if let cardModel = results.first {
                        if cardModel.confidence*100 > 60 {
                            if cardModel.identifier == "Hong Kong New Smart Identity Card" {
                                self?.cardModel = HKIDCardModel.new.rawValue
                            } else if cardModel.identifier == "Hong Kong Smart Identity Card" {
                                self?.cardModel = HKIDCardModel.old.rawValue
                            } else {
                                self?.cardModel = HKIDCardModel.unknown.rawValue
                                self?.showAlert = true
                            }
                        } else {
                            self?.cardModel = HKIDCardModel.unknown.rawValue
                            self?.showAlert = true
                        }
       
                        if Int(cardModel.confidence * 100) > 1 {
                            print("Detected \(cardModel.identifier) with \(cardModel.confidence*100)")
                        }
                        
                        self?.isCardRecognizing = false
                    }
                }
            }
        })
        
        return request
    }
    
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest {
        let v = VNDetectFaceRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                    print("did detect \(results.count) face(s)")
                    
                    let originalFace: UIImage = self.source!
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
    
    private func storeEnglish(_ candidate: VNRecognizedText) -> CGRect? {
        let data = candidate.string
        
        var boundingBox: CGRect? = nil
        
        if self.englishName == nil, let englishName = data.matchingStrings(regex: "[a-zA-Z\\s]{1,}\\,[a-zA-Z\\s]{0,}").first?[0] {
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
            
            boundingBox = self.getBoundingBox(candidate: candidate)
            
            // print(boundingBox)
            
            // If the bounding box is contain the sex field -> width: 0.32764844894409184
            // Optional((0.38202315966288247, 0.571360644915246, 0.32764844894409184, 0.06679375124293452))
            
            // If not -> width: 0.21767272949218752
            // Optional((0.39470877298494667, 0.5736197233200073, 0.21767272949218752, 0.050992608070373535))
            
            // If contain the sex field reduce it by 0.08
            if boundingBox != nil && boundingBox!.width > 0.27 {
                boundingBox = CGRect(x: boundingBox!.minX, y: boundingBox!.minY, width: boundingBox!.width - 0.08, height: boundingBox!.height)
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
                
                boundingBox = self.getBoundingBox(candidate: candidate)
                //print(boundingBox)
                // Optional((0.37682926829268293, 0.865234375, 0.5975609756097562, 0.06640625))
                if boundingBox != nil {
                    boundingBox = CGRect(
                        x: boundingBox!.minX + boundingBox!.width / 2.1,
                        y: boundingBox!.minY,
                        width: boundingBox!.width / 1.9,
                        height: boundingBox!.height
                    )
                }
            }
        } else if let number = data.matchingStrings(regex: "[A-Z0-9]{7}\\s{0,1}.[A-E0-9]\\)").first?[0] {
            var number = number.removingWhitespaces()
            if number.first! == "7" { number = "Z" + number.dropFirst() }
            self.number = number
            print("self.number \(self.number!)")
            boundingBox = self.getBoundingBox(candidate: candidate)
            //print(boundingBox)
            // Optional((0.6846289038658142, 0.8742822611107016, 0.2881550192832947, 0.05337111754987223))
            // Optional((0.623229668746808, 0.8368828773498536, 0.3060696127465845, 0.05862817764282224))
        } else if data.matchingStrings(regex: "\\*").first?[0] == "*" && data.count < 10 {
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
        
        return boundingBox
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

extension UIImage {
    func drawRectangleOnImage(rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        
        self.draw(at: CGPoint.zero)

        UIColor.black.setFill()
        
        UIRectFill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

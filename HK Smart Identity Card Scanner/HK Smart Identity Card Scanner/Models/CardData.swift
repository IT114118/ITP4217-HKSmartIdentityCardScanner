//
//  CardData.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 5/4/2021.
//

import Foundation

class CardData: ObservableObject {
    var chineseName: String?
    var englishName: String?
    var dateOfBirth: String?
    var dateofIssue: String?
    var dateofRegistration: String?
    var sex: String?
    var ccc: [Int]?
    var symbols: String?
    var number: String?
    
    func reset() {
        self.chineseName = nil
        self.englishName = nil
        self.dateOfBirth = nil
        self.dateofIssue = nil
        self.dateofRegistration = nil
        self.sex = nil
        self.ccc = nil
        self.symbols = nil
        self.number = nil
    }
    
    func printResult() {
        print("self.chineseName \(self.chineseName)")
        print("self.englishName \(self.englishName)")
        print("self.dateOfBirth \(self.dateOfBirth)")
        print("self.dateofIssue \(self.dateofIssue)")
        print("self.dateofRegistration \(self.dateofRegistration)")
        print("self.sex \(self.sex)")
        print("self.ccc \(self.ccc)")
        print("self.symbols \(self.symbols)")
        print("self.number \(self.number)")
    }
    
    func store(_ data: String) {
        if self.englishName == nil, let englishName = data.matchingStrings(regex: "[a-zA-Z\\s]{1,}\\,[a-zA-Z\\s]{1,}").first?[0] {
            self.englishName = englishName
            print("self.englishName \(self.englishName!)")
        } else if self.ccc == nil, let cccString = data.matchingStrings(regex: "[0-9\\s]{4,}").first?[0], cccString.count > 4 && cccString[String.Index(encodedOffset: 4)] == " " {
            
            self.ccc = [Int]()
            self.chineseName = ""
            
            let subs = cccString.split(separator: " ")
            for sub in subs {
                self.ccc?.append(Int(sub)!)
                self.chineseName? += ChineseCommercialCodeService.convertToText(String(sub))
            }
            
            print("self.ccc \(self.ccc!)")
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
        } else if self.dateofIssue == nil, let dateofIssue = data.matchingStrings(regex: "\\([0-9]{1,}\\-[0-9]{1,}\\)").first?[0] {
            self.dateofIssue = dateofIssue
            print("self.dateofIssue \(self.dateofIssue!)")
        } else if self.dateofRegistration == nil, let dateofRegistration = data.matchingStrings(regex: "[0-9\\s]{2,}-[0-9\\s]{2,}-[0-9\\s]{2}").first?[0] {
            self.dateofRegistration = dateofRegistration.removingWhitespaces()
            print("self.dateofRegistration \(self.dateofRegistration!)")
            
            if let number = data.matchingStrings(regex: "[A-Z0-9]{7}.{0,1}\\([A-D0-9]\\)").first?[0] {
                self.number = number.removingWhitespaces()
                print("self.number \(self.number!)")
            }
        } else if let number = data.matchingStrings(regex: "[A-Z0-9]{7}.{0,1}\\([A-D0-9]\\)").first?[0] {
            self.number = number.removingWhitespaces()
            print("self.number \(self.number!)")
        } else if let containSymbols = data.matchingStrings(regex: "\\*").first?[0] {
            self.symbols = data
            print("self.symbols \(self.symbols!)")
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
}

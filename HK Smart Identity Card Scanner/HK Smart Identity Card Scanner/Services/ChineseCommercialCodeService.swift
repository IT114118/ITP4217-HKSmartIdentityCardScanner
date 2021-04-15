//
//  ChineseCommercialCodeService.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 6/4/2021.
//

import Foundation
import SwiftyJSON

class ChineseCommercialCodeService {
    static func convertToText(_ code: String) -> String {
        let path = Bundle.main.path(forResource: "ctc2hanzi", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!), options: .mappedIfSafe)
        let json = try! JSON(data: data)

        if let text = json[code].string {
            return text
        }
        
        return ""
    }
}

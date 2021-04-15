//
//  Card+CoreDataProperties.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 7/4/2021.
//
//

import Foundation
import CoreData


extension Card {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Card> {
        return NSFetchRequest<Card>(entityName: "Card")
    }

    @NSManaged public var chineseName: String?
    @NSManaged public var englishName: String?
    @NSManaged public var dateOfBirth: String?
    @NSManaged public var dateOfIssue: String?
    @NSManaged public var dateOfRegistration: String?
    @NSManaged public var sex: String?
    @NSManaged public var ccc: String?
    @NSManaged public var symbols: String?
    @NSManaged public var number: String?
    @NSManaged public var face: Data?

}

extension Card : Identifiable {

}

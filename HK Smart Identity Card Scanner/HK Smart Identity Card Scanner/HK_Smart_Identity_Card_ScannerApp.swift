//
//  HK_Smart_Identity_Card_ScannerApp.swift
//  HK Smart Identity Card Scanner
//
//  Created by Battlefield Duck on 5/4/2021.
//

import SwiftUI

@main
struct HK_Smart_Identity_Card_ScannerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

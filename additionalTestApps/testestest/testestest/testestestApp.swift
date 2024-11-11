//
//  testestestApp.swift
//  testestest
//
//  Created by Alan Bohannon on 12/1/22.
//

import SwiftUI

@main
struct testestestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

 //
//  VibespreaPrototypeApp.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/3/22.
//

import SwiftUI


@main
struct VibespreaPrototypeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

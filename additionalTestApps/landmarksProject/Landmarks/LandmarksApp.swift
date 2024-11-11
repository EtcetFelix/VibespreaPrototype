//
//  LandmarksApp.swift
//  Landmarks
//
//  Created by Alan Bohannon on 12/4/22.
//

import SwiftUI

@main
struct LandmarksApp: App {
    @StateObject private var modelData = ModelData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelData)
        }
    }
}

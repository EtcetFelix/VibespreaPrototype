//
//  ContentView.swift
//  Landmarks
//
//  Created by Alan Bohannon on 12/4/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        LandmarkList()
            
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelData())
    }
}

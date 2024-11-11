//
//  HomeScreen.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/9/22.
//

import SwiftUI
import CoreBluetooth

struct HomeScreen: View {
//    @StateObject var pmDelegate = PeripheralManagerDelegate()
    @StateObject private var modelData = AppModel()
    @State private var showDetail = true

    
    var body: some View {
        VStack {
            // Advertise button
            DropDownButton(buttonText: modelData.advertiseText,
                           buttonDroppedText: "Advertising...Beep Bepp Bepp beep",
                           buttonDroppedTruth: modelData.peripheralManagerDelegate.isAdvertising,
                           actionToTake: {modelData.flipIsAdvertising()})
            // Create mesh network button
            DropDownButton(buttonText: "Create Mesh Network",
                           buttonDroppedText: "Created Mesh network",
                           buttonDroppedTruth: modelData.createdMeshNetwork,
                           actionToTake: {modelData.createMeshNetwork()})
            // Scan peripherals button
            DropDownButton(buttonText: modelData.scanningText,
                           buttonDroppedText: "Scanning...Scanning...Biiiing....Biiing",
                           buttonDroppedTruth: modelData.centralManagerDelegate.isScanning,
                           actionToTake: {modelData.flipIsScanning()})
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}

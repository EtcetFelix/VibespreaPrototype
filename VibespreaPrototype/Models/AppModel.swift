//
//  PeripheralModel.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/10/22.
//

import Foundation
import Combine
import CoreBluetooth
import nRFMeshProvision

final class AppModel: ObservableObject {
    let appDelegate = AppMeshNetworkDelegate()
    let meshServiceUUID = nRFMeshProvision.MeshProvisioningService.uuid
    var peripheralManagerDelegate = PeripheralManagerDelegateForProvisioning()
    let centralManagerDelegate = CentralManagerDelegate()
    let peripheralManager: CBPeripheralManager!
    let centralManager: CBCentralManager!
    @Published var advertiseText: String
    var startAdvText = "Start Advertising"
    var stopAdvText = "Stop Advertising"
    @Published var scanningText: String
    var startScanText = "Start Scanning"
    var stopScanText = "Stop Scanning"
    @Published var createdMeshNetwork = false
    
    init() {
        peripheralManagerDelegate.unprovisionedDeviceDelegate = appDelegate
        if peripheralManagerDelegate.isAdvertising {
            advertiseText = stopAdvText
        }
        else {
            advertiseText = startAdvText
        }
        if centralManagerDelegate.isScanning {
            scanningText = stopScanText
        }
        else {
            scanningText = startScanText
        }
        peripheralManager = CBPeripheralManager(delegate: peripheralManagerDelegate, queue: nil)
        centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: nil)
    }
    
    func flipIsAdvertising() {
        if peripheralManagerDelegate.isAdvertising {
            requestToStopAdvertising()
        }
        else {
            requestToAdvertise()
        }
        updateAdvertiseText()
    }
    
    func flipIsScanning() {
        if centralManager.isScanning {
            requestToStopScanning()
        }
        else if createdMeshNetwork{
            requestToScan()
        }
        else {
            print("Start a mesh network first doofus")
        }
        updateScanningText()
    }
    
    func requestToAdvertise() {
        peripheralManagerDelegate.requestStartAdvertise(peripheralManager: peripheralManager)
        updateAdvertiseText()
    }
    
    func requestToStopAdvertising() {
        peripheralManagerDelegate.stopAdvertising(peripheralManager: peripheralManager)
        updateAdvertiseText()
    }
    
    func requestToScan() {
        centralManagerDelegate.requestStartScanning(centralManager: centralManager, services: [meshServiceUUID])
        updateAdvertiseText()
    }
    
    func requestToStopScanning() {
        centralManagerDelegate.requestStopScan(centralManager: centralManager)
        updateAdvertiseText()
    }
    
    func updateAdvertiseText() {
        if peripheralManagerDelegate.isAdvertising {
            advertiseText = stopAdvText
        }
        else {
            advertiseText = startAdvText
        }
    }
    
    func updateScanningText() {
        if peripheralManagerDelegate.isAdvertising {
            advertiseText = stopAdvText
        }
        else {
            advertiseText = startAdvText
        }
    }
    
    func createMeshNetwork() {
        appDelegate.createNewMeshNetwork()
        createdMeshNetwork = true
        centralManagerDelegate.meshNetworkManager = appDelegate.meshNetworkManager
    }
    
}

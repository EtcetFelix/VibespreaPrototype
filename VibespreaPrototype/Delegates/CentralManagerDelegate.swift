//
//  CentralManagerDelegate.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/13/22.
//

import Foundation
import CoreBluetooth
import nRFMeshProvision

class CentralManagerDelegate: NSObject, ObservableObject, CBCentralManagerDelegate  {
    var isPoweredOn = false
    @Published var isScanning: Bool = false
    var meshNetworkManager: MeshNetworkManager?
    let provisioningBearerDelegate = ProvisioningBearerDelegate()
    var gattBearer: PBGattBearer!
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth Device is UNKNOWN")
            isScanning = false
            isPoweredOn = false
        case .unsupported:
            print("Bluetooth Device is UNSUPPORTED")
            isScanning = false
            isPoweredOn = false
        case .unauthorized:
            print("Bluetooth Device is UNAUTHORIZED")
            isScanning = false
            isPoweredOn = false
        case .resetting:
            print("Bluetooth Device is RESETTING")
            isScanning = false
            isPoweredOn = false
        case .poweredOff:
            print("Bluetooth Device is POWERED OFF")
            isScanning = false
            isPoweredOn = false
        case .poweredOn:
            print("Bluetooth Device is POWERED ON")
            isPoweredOn = true
        @unknown default:
            print("Unknown State")
            isPoweredOn = false
        }
    }
    
    func requestStartScanning(centralManager: CBCentralManager, services: [CBUUID]) {
        centralManager.scanForPeripherals(withServices: services)
        isScanning = true
        print("Scanning")
    }
    
    func requestStopScan(centralManager: CBCentralManager) {
        centralManager.stopScan()
        isScanning = false
        print("Scanning stopped")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral.name ?? "{no name}").\n printing ad data:")
        print("\(advertisementData as AnyObject)")
        provisionUnprovisionedDevice(peripheral: peripheral)
    }
    
    func provisionUnprovisionedDevice(peripheral: CBPeripheral) {
        let unprovisionedDevice = UnprovisionedDevice(uuid: peripheral.identifier)
        provisioningBearerDelegate.unprovisionedDevice = unprovisionedDevice
        provisioningBearerDelegate.meshNetworkManager = meshNetworkManager
        gattBearer = PBGattBearer(target: peripheral)
        provisioningBearerDelegate.gattBearer = gattBearer
        gattBearer.delegate = provisioningBearerDelegate
        gattBearer.open()
        // After the bearer is opened, the bearer delegate's bearerDidOpen function is called to continue provisioning
    }
    
    
}

//
//  AppDelegate.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/12/22.
//

import Foundation
import UIKit
import os.log
import nRFMeshProvision

class AppMeshNetworkDelegate: UnprovisionedDeviceProvisioning {
    
    
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection!
    
    var meshName = "Vibesprea Prototype"
    
    init() {
        meshNetworkManager = MeshNetworkManager()
        
        print("Initialized AppDelegate and meshNetworkManager")
    }
    
    /// This method creates a new mesh network with a default name and a
    /// single Provisioner. When done, if calls `meshNetworkDidChange()`.
    func createNewMeshNetwork() {
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        _ = meshNetworkManager.createNewMeshNetwork(withName: meshName, by: provisioner)
        _ = meshNetworkManager.save()
        
        meshNetworkDidChange()
        print("Created mesh network")
        let data = meshNetworkManager.export(.full)
        print(String(data: data, encoding: .utf8)!)
    }
    
    func didReceiveProvisioningData(data: Data) {
        // Create mesh network from provisioning data
        // TODO: make sure provisioner address ranges don't interfere with other provisioners
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        // TODO: pass netkey and unicast address to meshnetworknewdevice constructor
        // parse the network key
        let key = data.subdata(in: 0..<16)
        let keyIndex = data.subdata(in: 16..<18)
        let flags = data.subdata(in: 18..<19)
        let ivIndexBytes = data.subdata(in: 19..<23)
        let unicastAddress = data.subdata(in: 23..<25)
        var ivIndex: UInt16 {
            ivIndexBytes.withUnsafeBytes { $0.bindMemory(to: UInt16.self) }[0]
        }
        
        guard let meshNetNewDevice = MeshNetworkNewDevice(name: meshName, uuid: UUID(), provisioner: provisioner, keyIndex: 1, key: key) else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if #available(iOS 11.0, *) {
            encoder.outputFormatting = .sortedKeys
        }
        do{
            let data = try exportNetwork(meshNet: meshNetNewDevice)
            print(String(data: data, encoding: .utf8)!)
            print("\n")
            do {
                let actualMeshNet = try meshNetworkManager.import(from: data)
                let actualMeshNetExport = try exportNetwork(meshNet: actualMeshNet)
                print(String(data: actualMeshNetExport, encoding: .utf8)!)
            }
            catch {
                print("error importing, dumping error: ")
                dump(error)
            }
        }
        catch {
            print("error exporting, dumping error: ")
            dump(error)
        }
        print("\n")
        print("provisioned!")
    }
    
    func createPreSavedMeshNetwork() {
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        guard let meshNetNewDevice = MeshNetworkNewDevice(name: meshName, uuid: UUID(), provisioner: provisioner, keyIndex: 0, key: Data()) else {
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if #available(iOS 11.0, *) {
            encoder.outputFormatting = .sortedKeys
        }
        do{
            let data = try exportNetwork(meshNet: meshNetNewDevice)
            print(String(data: data, encoding: .utf8)!)
            print("\n")
            do {
                let actualMeshNet = try meshNetworkManager.import(from: data)
                let actualMeshNetExport = try exportNetwork(meshNet: actualMeshNet)
                print(String(data: actualMeshNetExport, encoding: .utf8)!)
            }
            catch {
                print("error importing, dumping error: ")
                dump(error)
            }
        }
        catch {
            print("error exporting, dumping error: ")
            dump(error)
        }
    }
    
    func exportNetwork(meshNet: MeshNetworkNewDevice) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if #available(iOS 11.0, *) {
            encoder.outputFormatting = .sortedKeys
        }
        
        return try encoder.encode(meshNet)
    }
    func exportNetwork(meshNet: MeshNetwork) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if #available(iOS 11.0, *) {
            encoder.outputFormatting = .sortedKeys
        }
        
        return try encoder.encode(meshNet)
    }
    
    /// Sets up the local Elements and reinitializes the `NetworkConnection`
    /// so that it starts scanning for devices advertising the new Network ID.
    func meshNetworkDidChange() {
        connection?.close()
        
        let meshNetwork = meshNetworkManager.meshNetwork!
        
        connection = NetworkConnection(to: meshNetwork)
        connection!.dataDelegate = meshNetworkManager
        connection!.logger = self
        meshNetworkManager.transmitter = connection
        connection!.open()
    }
}

// MARK: - Logger
extension AppMeshNetworkDelegate: LoggerDelegate {
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        if #available(iOS 10.0, *) {
            os_log("%{public}@", log: category.log, type: level.type, message)
        } else {
            NSLog("%@", message)
        }
    }
}

extension LogLevel {
    /// Mapping from mesh log levels to system log types.
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
}

extension LogCategory {
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
}


//
//  BearerDelegate.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/18/22.
//

import Foundation
import nRFMeshProvision

class ProvisioningBearerDelegate: GattBearerDelegate {
    
    var unprovisionedDevice: UnprovisionedDevice!
    var meshNetworkManager: MeshNetworkManager!
    var gattBearer: PBGattBearer!
    var provisioningManagerDelegate: ProvisioningManagerDelegate!
    var provisioningManager: ProvisioningManager!
    
    init() {
        provisioningManagerDelegate = ProvisioningManagerDelegate(bearerDelegate: self)
    }
    
    func bearer(_ bearer: nRFMeshProvision.Bearer, didClose error: Error?) {
        print("BEARER DELEGATE Bearer closed with error. Error:")
        dump(error)
    }
    
    func bearerDidOpen(_ bearer: nRFMeshProvision.Bearer) {
        print("BEARER DELEGATE Bearer Opened")
        ensureUnprovisionedDeviceAssigned()
        do {
            print("Attempting to create provisioning manager")
            provisioningManager = try meshNetworkManager?.provision(
                        unprovisionedDevice: unprovisionedDevice,
                        over: gattBearer
                    )
            print("Provisioining manager made")
            provisioningManager!.delegate = provisioningManagerDelegate
            print("After provisioning manager delegate assigned")
            let data = meshNetworkManager.export(.full)
            do {
                // identify the device to be provisionined
                try provisioningManager!.identify(andAttractFor: 2 /* seconds */)
                print("Trying to identify device")
            }
            catch {
                print("Unexpected Error: \(error)")
                gattBearer.close()
            }
        }
        catch {
            print("Unexpected error when making provisioning manager: \(error)")
        }

    }
    
    func ensureUnprovisionedDeviceAssigned(){
        guard unprovisionedDevice != nil else {
            print("UnprovisionedDevice not assigned")
            return
        }
    }
    
    func bearerDidConnect(_ bearer: Bearer) {
        print("BEARER DELEGATE Bearer did connect")
    }
    
    func startProvisioning() {
        print("Starting provisioning in bearer delegate")
        let publicKey: PublicKey = .noOobPublicKey
        let authenticationMethod: AuthenticationMethod = .noOob
        do {
            try provisioningManager!.provision(usingAlgorithm: .fipsP256EllipticCurve,
                                                  publicKey: publicKey,
                                                  authenticationMethod: authenticationMethod)
        }
        catch {
            print("SOMETHING WENT WRONG WHEN CALLING PROVISIONING MANAGER.PROVISION")
        }
    }
    
    
}

//
//  ProvisioningManagerDelegate.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/17/22.
//

import Foundation
import nRFMeshProvision

class ProvisioningManagerDelegate: NSObject, ObservableObject, ProvisioningDelegate {
    var bearerDelegate: ProvisioningBearerDelegate
    
    init(bearerDelegate: ProvisioningBearerDelegate) {
        self.bearerDelegate = bearerDelegate
    }
    
    /// Callback called when an authentication action is required
    /// from the user.
    ///
    /// - parameter action: The action to be performed.
    func authenticationActionRequired(_ action: nRFMeshProvision.AuthAction) {
        switch action {
            case .provideStaticKey(let callback):
                print("Auth action required: provide static key to callback")
            case .provideNumeric(let maximumNumberOfDigits, let outputAction, let callback):
                print("Auth action required: provide numeric")
                dump(maximumNumberOfDigits)
                dump(outputAction)
            case .provideAlphanumeric(let maximumNumberOfCharacters, let callback):
                print("Auth action required: provide alphanumeric")
                dump(maximumNumberOfCharacters)
            case .displayNumber(let value, let inputAction):
                print("Auth action required: display number")
                dump(value)
                dump(inputAction)
            case .displayAlphanumeric(let text):
                print("Auth action required: display alphanumeric")
                dump(text)
            @unknown default:
                print("Unknown action required")
        }
    }
    
    /// Callback called when the user finished Input Action on the
    /// device.
    func inputComplete() {
        print("PROVISIONING INPUT COMPLETE")
    }
    
    /// Callback called whenever the provisioning status changes.
    ///
    /// - parameter unprovisionedDevice: The device which state has changed.
    /// - parameter state:               The completed provisioning state.
    func provisioningState(of unprovisionedDevice: nRFMeshProvision.UnprovisionedDevice, didChangeTo state: nRFMeshProvision.ProvisioningState) {
        switch state {
        case .ready:
            print("Provisioning Manager is ready to start.")
        case .requestingCapabilities:
            print("The manager is requesting Provisioning Capabilities from the device.")
        case .capabilitiesReceived(_ /*let capabilities*/):
            print("ProvManagerDelegate: Provisioning Capabilities were received. Starting provisioning...")
            bearerDelegate.startProvisioning()
        case .provisioning:
            print("Provisioning has been started.")
        case .complete:
            print("The provisioning process is complete.")
        case .fail(let error):
            print("The provisioning has failed because of a local error.")
            dump(error)
        @unknown default:
            print("Unknown provisioning state")
        }
    }
    
    
    
    
}

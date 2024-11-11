//
//  ProvisioningData.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/24/22.
//

import Foundation
import nRFMeshProvision

internal class ProvisioningData {
//    private(set) var networkKey: NetworkKey!
//    private(set) var ivIndex: IvIndex!
//    private(set) var unicastAddress: Address!

    private var privateKey: SecKey!
    private var publicKey: SecKey!
    private var sharedSecret: Data!
    private var authValue: Data!
    private var provisionerConfirmation: Data!
    private var provisionerRandom: Data!

//    private(set) var deviceKey: Data!
    private(set) var deviceRandom: Data!
    private(set) var newDevicePublicKey: Data!
    
    /// The Confirmation Inputs is built over the provisioning process.
    /// It is composed for: Provisioning Invite PDU, Provisioning Capabilities PDU,
    /// Provisioning Start PDU, Provisioner's Public Key and device's Public Key.
    private var confirmationInputs: Data = Data(capacity: 1 + 11 + 5 + 64 + 64)

//    func prepare(for network: MeshNetwork, networkKey: NetworkKey, unicastAddress: Address) {
//        self.networkKey     = networkKey
//        self.ivIndex        = network.ivIndex
//        self.unicastAddress = unicastAddress
//    }

    func generateKeys(usingAlgorithm algorithm: Algorithm) throws {
        // Generate Private and Public Keys.
        let (sk, pk) = try Crypto.generateKeyPair(using: algorithm)
        privateKey = sk
        publicKey  = pk
        try newDevicePublicKey = pk.toData()

        // Generate Provisioner Random.
        deviceRandom = Crypto.generateRandom()
    }

}

internal extension ProvisioningData {

    /// This method adds the given PDU to the Provisioning Inputs.
    /// Provisioning Inputs are used for authenticating the Provisioner
    /// and the Unprovisioned Device in the 4th step of the provisioning
    /// procedure: authentication.
    /// This method must be called (in order) for:
    /// * Provisioning Invite
    /// * Provisioning Capabilities
    /// * Provisioning Start
    /// * Provisioner Public Key
    /// * Device Public Key
    func accumulate(pdu: Data) {
        confirmationInputs += pdu
    }

    /// Call this method when the provisioner Public Key has been
    /// obtained. This must be called after generating keys.
    ///
    /// - parameter key: The provisioner Public Key.
    /// - throws: This method throws when generating ECDH Secure
    ///           Secret failed.
    func deviceDidObtain(provisionerPublicKey key: Data) throws {
        guard let _ = privateKey else {
            throw ProvisioningError.invalidState
        }
        sharedSecret = try Crypto.calculateSharedSecret(privateKey: privateKey, publicKey: key)
    }

    /// Call this method when the Auth Value has been obtained.
    func deviceDidObtain(authValue data: Data) {
        authValue = data
    }

    /// Call this method when the device Provisioning Confirmation
    /// has been obtained.
    func deviceDidObtain(provisionerConfirmation data: Data) {
        provisionerConfirmation = data
    }

    /// Call this method when the provisioner Provisioning Random
    /// has been obtained.
    func deviceDidObtain(provisionerRandom data: Data) {
        provisionerRandom = data
    }

    /// This method validates the received Provisioning Confirmation and
    /// matches it with one calculated locally based on the Provisioning
    /// Random received from the provisioner and Auth Value.
    ///
    /// - throws: The method throws when the validation failed, or
    ///           it was called before all data were ready.
    func validateConfirmation() throws {
        guard let provisionerRandom = provisionerRandom,
              let authValue = authValue,
              let sharedSecret = sharedSecret else {
            throw ProvisioningError.invalidState
        }
        let confirmation = Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                                        sharedSecret: sharedSecret,
                                                        random: provisionerRandom, authValue: authValue)
        guard provisionerConfirmation == confirmation else {
            throw ProvisioningError.confirmationFailed
        }
    }

    /// Returns the device Confirmation value. The Auth Value
    /// must be set prior to calling this method.
    var deviceConfirmation: Data {
        return Crypto.calculateConfirmation(confirmationInputs: confirmationInputs,
                                            sharedSecret: sharedSecret!,
                                            random: deviceRandom, authValue: authValue)
    }

//    /// Returns the encrypted Provisioning Data together with MIC.
//    /// Data will be encrypted using Session Key and Session Nonce.
//    /// For that, all properties should be set when this method is called.
//    /// Returned value is 25 + 8 bytes long, where the MIC is the last 8 bytes.
//    var encryptedProvisioningDataWithMic: Data {
//        let keys = Crypto.calculateKeys(confirmationInputs: confirmationInputs,
//                                        sharedSecret: sharedSecret!,
//                                        provisionerRandom: provisionerRandom,
//                                        deviceRandom: deviceRandom)
//        deviceKey = keys.deviceKey
//
//        let flags = Flags(ivIndex: ivIndex, networkKey: networkKey)
//        let key   = networkKey.phase == .keyDistribution ? networkKey.oldKey! : networkKey.key
//        let data  = key + networkKey.index.bigEndian + flags.rawValue
//                        + ivIndex.index.bigEndian + unicastAddress.bigEndian
//        return Crypto.encrypt(provisioningData: data,
//                              usingSessionKey: keys.sessionKey, andNonce: keys.sessionNonce)
//    }
    
    func decryptedProvisioningData(data: Data, mic: Data) -> Data? {
        let keys = Crypto.calculateKeys(confirmationInputs: confirmationInputs,
                                        sharedSecret: sharedSecret!,
                                        provisionerRandom: provisionerRandom,
                                        deviceRandom: deviceRandom)
        return Crypto.decrypt(data: data, mic: mic, keys: keys)
    }

}

//// MARK: - Helper methods
//
////private struct Flags: OptionSet {
////    let rawValue: UInt8
////
////    static let useNewKeys     = Flags(rawValue: 1 << 0)
////    static let ivUpdateActive = Flags(rawValue: 1 << 1)
////
////    init(rawValue: UInt8) {
////        self.rawValue = rawValue
////    }
////
////    init(ivIndex: IvIndex, networkKey: NetworkKey) {
////        var value: UInt8 = 0
////        if case .usingNewKeys = networkKey.phase {
////            value |= 1 << 0
////        }
////        if ivIndex.updateActive {
////            value |= 1 << 1
////        }
////        self.rawValue = value
////    }
////}

private extension SecKey {

    /// Returns the Public Key as Data from the SecKey. The SecKey must contain the
    /// valid public key.
    func toData() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let representation = SecKeyCopyExternalRepresentation(self, &error) else {
            throw error!.takeRetainedValue()
        }
        let data = representation as Data
        // First is 0x04 to indicate uncompressed representation.
        return data.dropFirst()
    }

}

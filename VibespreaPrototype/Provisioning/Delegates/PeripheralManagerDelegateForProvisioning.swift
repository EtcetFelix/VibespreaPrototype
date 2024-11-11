//
//  bleManager.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/10/22.
//

import Foundation
import CoreBluetooth
import nRFMeshProvision

class PeripheralManagerDelegateForProvisioning: NSObject, ObservableObject, CBPeripheralManagerDelegate  {
    var isPoweredOn = false
    var unprovisionedDeviceDelegate: UnprovisionedDeviceProvisioning!
    @Published var isAdvertising: Bool = false
    let meshServiceUUID = nRFMeshProvision.MeshProvisioningService.uuid
    
    var dataOutChar: CBMutableCharacteristic!
    var dataInChar : CBMutableCharacteristic!
    
    var provisioningData: ProvisioningData!
    var authenticationMethod: AuthenticationMethod!
    
    /// The current state of the provisioning process.
    private var state: ProvisionRequestState = .beaconing {
        didSet {
            if case .fail = state {
                print("PeripheralManagerDelegate: \(state)")
            } else {
                print("PeripheralManagerDelegate: \(state)")
            }
        }
    }
    
    init(dataOutChar: CBMutableCharacteristic, dataInChar: CBMutableCharacteristic) {
        self.dataOutChar = dataOutChar
        self.dataInChar = dataInChar
        super.init()
    }
    
    convenience override init() {
        let dataInCharUUID = nRFMeshProvision.MeshProvisioningService.dataInUuid
        let dataOutCharUUID = nRFMeshProvision.MeshProvisioningService.dataOutUuid
        // TODO: REMOVE THE WRITE, AND READ PROPERTIES FROM BOTH CHARS. REMOVE NOTIFY FROM DATAIN
        let dataOutChar = CBMutableCharacteristic(type: dataOutCharUUID, properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
        let dataInChar = CBMutableCharacteristic(type: dataInCharUUID, properties: [.notify, .write, .read, .writeWithoutResponse], value: nil, permissions: [.readable, .writeable])
        self.init(dataOutChar: dataOutChar, dataInChar: dataInChar)
    }
    
    convenience init(delegate: UnprovisionedDeviceProvisioning) {
        self.init()
        unprovisionedDeviceDelegate = delegate
    }
    
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // do code here for when CBPeripheralManagerState.poweredOff happens
        switch peripheral.state {
            case .unknown:
                print("Bluetooth Device is UNKNOWN")
                isAdvertising = false
                isPoweredOn = false
            case .unsupported:
                print("Bluetooth Device is UNSUPPORTED")
                isAdvertising = false
                isPoweredOn = false
            case .unauthorized:
                print("Bluetooth Device is UNAUTHORIZED")
                isAdvertising = false
                isPoweredOn = false
            case .resetting:
                print("Bluetooth Device is RESETTING")
                isAdvertising = false
                isPoweredOn = false
            case .poweredOff:
                print("Bluetooth Device is POWERED OFF")
                isAdvertising = false
                isPoweredOn = false
            case .poweredOn:
                print("Bluetooth Device is POWERED ON")
                isPoweredOn = true
            @unknown default:
                print("Unknown State")
                isPoweredOn = false
            }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        // do code here for when advertising starts
        isAdvertising = true
    }

    func startAdvertising(peripheralManager: CBPeripheralManager, service: CBMutableService) {
        isAdvertising = true
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey : "VibespreaProtoMeshApp",
                                         CBAdvertisementDataServiceUUIDsKey : [service.uuid]])
        print("Started Advertising")
    }
    
    func stopAdvertising(peripheralManager: CBPeripheralManager) {
        isAdvertising = false
        peripheralManager.stopAdvertising()
    }
    
    
    func addServices(peripheralManager: CBPeripheralManager) {
        // Both dataIn and dataOut characteristics are required for a mesh node to provision a peripheral.
        // Data out requires at least the notify property
        let meshProvisioningService = CBMutableService(type: meshServiceUUID, primary: true)
        meshProvisioningService.characteristics = [dataOutChar, dataInChar]
        peripheralManager.add(meshProvisioningService)
        startAdvertising(peripheralManager: peripheralManager, service: meshProvisioningService)
    }
    
    func requestStartAdvertise(peripheralManager : CBPeripheralManager) {
        if isPoweredOn {
            addServices(peripheralManager: peripheralManager)
        }
    }
    
    func send(provisioningPdu: Data, peripheral: CBPeripheralManager) {
        // Create a proxy pdu of provisioningPdu type
        var proxyPdu = Data([PduType.provisioningPdu.rawValue])
        proxyPdu += provisioningPdu
        dataOutChar.value = proxyPdu
        peripheral.updateValue(proxyPdu, for: dataOutChar, onSubscribedCentrals: nil)
        let rawValueProvisioningPduTypeSent = provisioningPdu[0]
        let provisioningPduTypeSent = ProvisioningPduType(rawValue: rawValueProvisioningPduTypeSent)
        print("PeripheralManagerDelegate: ProvisioningPdu of type \(provisioningPduTypeSent) sent")
    }
        
    // MARK: - Did Receive Write
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("received write request")
        for request in requests {
            let mutableChar = request.characteristic as? CBMutableCharacteristic
            print("char before changing: \(mutableChar?.value)")
            mutableChar?.value = request.value!
            print("char after changing: \(mutableChar?.value)")
            let data = request.value!
            dump(data)
            // Drop the proxy pdu type to get the provisioningPdu
            let pduData = data.subdata(in: 1..<data.count)
            
            guard let pduReceived = ProvisioningRequest(pduData) else {
                return
            }
            print("Pdu type received: \(pduReceived.type), current state: \(state)")
            
            // Act depending on the current state and the response received.
            switch (state, pduReceived.type) {
                
            case(.beaconing, .invite):
                // Initialize provisioning data.
                provisioningData = ProvisioningData()
                
                let capabilitiesPdu = createCapabilitesPdu()
                // Add the invitation pdu to the confirmation inputs
                provisioningData.accumulate(pdu: pduData.dropFirst())
                // Add the capabilities to the confirmation inputs
                provisioningData.accumulate(pdu: capabilitiesPdu.dropFirst())
                dataOutChar.value = capabilitiesPdu
                print("capabilites: \(capabilitiesPdu)")
                dump(capabilitiesPdu)
                state = .capabilitiesSent
                send(provisioningPdu: capabilitiesPdu, peripheral: peripheral)
            case(.capabilitiesSent, .start):
                // Set the authentication method from the one received
                authenticationMethod = pduReceived.authenticationMethod
                // Add the start pdu to confirmation inputs
                provisioningData.accumulate(pdu: pduData.dropFirst())
                state = .provisioning
            case(.provisioning, .publicKey):
                print("Public key pdu received")
                let provisionerKey = pduReceived.publicKey!
                // Add the publicKey of the provisioner to the confirmation inputs
                provisioningData.accumulate(pdu: pduData.dropFirst())
                do {
                    // Try generating Private and Public Keys. This may fail if the given
                    // algorithm is not supported.
                    try provisioningData.generateKeys(usingAlgorithm: .fipsP256EllipticCurve)
                }
                catch {
                    dump(error)
                    return
                }
                print("Keys generated")
                // Calculate the device's Shared Secret.
                do {
                    try provisioningData.deviceDidObtain(provisionerPublicKey: provisionerKey)
                    obtainAuthValue()
                } catch {
                    state = .fail(error)
                    print("FAILED in peripheralManagerDelegate trying to calculate shared secret")
                    return
                }
                
                // Create the publicKey pdu for this unprovisioned device's publicKey
                let unprovisionedDevicePublicKeyPdu = ProvisioningResponse.publicKey(provisioningData.newDevicePublicKey)
                // Add the publicKey of this unprovisioned device to the confirmation inputs
                provisioningData.accumulate(pdu: unprovisionedDevicePublicKeyPdu.pdu.dropFirst())
                // Put provisioning pdu type value to the front of the pdu about to be sent
                var provisioningPdu = Data([PduType.provisioningPdu.rawValue])
                provisioningPdu += unprovisionedDevicePublicKeyPdu.pdu
                dataOutChar.value = provisioningPdu
                peripheral.updateValue(provisioningPdu, for: dataOutChar, onSubscribedCentrals: nil)
                print("dataOutChar updated with public key")
            case(.provisioning, .confirmation):
                provisioningData.deviceDidObtain(provisionerConfirmation: pduReceived.confirmation!)
                let provisioningConfirmation = ProvisioningResponse.confirmation(provisioningData.deviceConfirmation)
                print("Sending \(provisioningConfirmation)")
                send(provisioningPdu: provisioningConfirmation.pdu, peripheral: peripheral)
            case(.provisioning, .random):
                print("Device should check confirmation and send its own provisioning random number")
                provisioningData.deviceDidObtain(provisionerRandom: pduReceived.random!)
                do {
                    try provisioningData.validateConfirmation()
                } catch {
                    state = .fail(error)
                }
                let provisioningRandom = ProvisioningResponse.random(provisioningData.deviceRandom)
                send(provisioningPdu: provisioningRandom.pdu, peripheral: peripheral)
            case(.provisioning, .data):
                print("Received encrypted data")
                // Decrypt the data
                let encryptedData = pduData.subdata(in: 1..<pduData.count-8)
                let mic = pduData.subdata(in: pduData.count-8..<pduData.count)
                guard let decryptedData = provisioningData.decryptedProvisioningData(data: encryptedData, mic: mic) else {
                    print("No proper decryption of data")
                    return
                }
                print("Decrypted the data")
                dump(decryptedData)
                
                // call a delegate function to tell the app delegate that we are done provisioning and it must create the mesh network on the newly provisioned device
                unprovisionedDeviceDelegate.didReceiveProvisioningData(data: decryptedData)
                let provisioningCompletePdu = ProvisioningResponse.provisioningComplete
                send(provisioningPdu: provisioningCompletePdu.pdu, peripheral: peripheral)
            default:
                state = .fail(ProvisioningError.invalidState)
            }
        }
        peripheral.respond(to: requests[0], withResult: .success)
    }
    
    func createCapabilitesPdu() -> Data{
        let capabilitesPdu = ProvisioningCapabilitiesPdu(
                                    numberOfElements: 1,
                                    algorithms: Algorithms.fipsP256EllipticCurve,
                                    publicKeyType: PublicKeyType(rawValue: 0),
                                    staticOobType: StaticOobType(rawValue: 0),
                                    outputOobSize: 0,
                                    outputOobActions: OutputOobActions(rawValue: 0),
                                    inputOobSize: 0,
                                    inputOobActions: InputOobActions(rawValue: 0))
        return capabilitesPdu!.capabilitiesPDU
    }

}

/// The enum defines possible state of provisioning process.
private enum ProvisionRequestState {
    /// Provisioning Manager is beaconing and ready to start.
    case beaconing
    /// Provisioning Capabilities were sent
    case capabilitiesSent
    /// Provisioning has been started.
    case provisioning
    /// The device sent its public key
    case authenticating
    /// The provisioning process is complete.
    case complete
    /// The provisioning has failed because of a local error.
    case fail(_ error: Error)
}


private extension PeripheralManagerDelegateForProvisioning {
    
    /// This method asks the user to provide a OOB value based on the
    /// authentication method specified in the provisioning process.
    /// For `.noOob` case, the value is automatically set to 0s.
    /// This method will call `authValueReceived(:)` when the value
    /// has been obtained.
    func obtainAuthValue() {
        switch self.authenticationMethod! {
        // For No OOB, the AuthValue is just 16 byte array filled with 0.
        case .noOob:
            let authValue = Data(count: 16)
            authValueReceived(authValue)
            
        // For Static OOB, the AuthValue is the Key entered by the user.
        // The key must be 16 bytes long.
        case .staticOob:
            print(".staticOob, no functionality for it for now")
//            delegate?.authenticationActionRequired(.provideStaticKey(callback: { key in
//                guard self.bearer.isOpen else {
//                    self.state = .fail(BearerError.bearerClosed)
//                    return
//                }
//                guard case .provisioning = self.state, let _ = self.provisioningData else {
//                    self.state = .fail(ProvisioningError.invalidState)
//                    return
//                }
//                self.delegate?.inputComplete()
//                self.authValueReceived(key)
//            }))
            
        // For Output OOB, the device will blink, beep, vibrate or display a
        // value, and the user must enter the value on the phone. The entered
        // value becomes a part of the AuthValue.
        case let .outputOob(action: action, size: size):
            print(".outputOob, no functionality for it for now")
//            switch action {
//            case .outputAlphanumeric:
//                delegate?.authenticationActionRequired(.provideAlphanumeric(maximumNumberOfCharacters: size, callback: { text in
//                    guard var authValue = text.data(using: .ascii) else {
//                        self.state = .fail(ProvisioningError.invalidOobValueFormat)
//                        return
//                    }
//                    guard self.bearer.isOpen else {
//                        self.state = .fail(BearerError.bearerClosed)
//                        return
//                    }
//                    guard case .provisioning = self.state, let _ = self.provisioningData else {
//                        self.state = .fail(ProvisioningError.invalidState)
//                        return
//                    }
//                    authValue += Data(count: 16 - authValue.count)
//                    self.delegate?.inputComplete()
//                    self.authValueReceived(authValue)
//                }))
//            case .blink, .beep, .vibrate, .outputNumeric:
//                delegate?.authenticationActionRequired(.provideNumeric(maximumNumberOfDigits: size, outputAction: action, callback: { value in
//                    guard self.bearer.isOpen else {
//                        self.state = .fail(BearerError.bearerClosed)
//                        return
//                    }
//                    guard case .provisioning = self.state, let _ = self.provisioningData else {
//                        self.state = .fail(ProvisioningError.invalidState)
//                        return
//                    }
//                    var authValue = Data(count: 16 - MemoryLayout.size(ofValue: value))
//                    authValue += value.bigEndian
//                    self.delegate?.inputComplete()
//                    self.authValueReceived(authValue)
//                }))
//            }
            
        case let .inputOob(action: action, size: size):
            print(".inputOob, no functionality for it for now")
//            switch action {
//            case .inputAlphanumeric:
//                let random = randomString(length: UInt(size))
//                authAction = .displayAlphanumeric(random)
//            case .push, .twist, .inputNumeric:
//                let random = randomInt(length: UInt(size))
//                authAction = .displayNumber(random, inputAction: action)
//            }
//            delegate?.authenticationActionRequired(authAction!)
        }
    }

    /// This method should be called when the OOB value has been received
    /// and Auth Value has been calculated.
    /// It computes and sends the Provisioner Confirmation to the device.
    ///
    /// - parameter value: The 16 byte long Auth Value.
    func authValueReceived(_ value: Data) {
//        authAction = nil
        provisioningData.deviceDidObtain(authValue: value)
//        do {
//            let provisioningConfirmation = ProvisioningRequest.confirmation(provisioningData.provisionerConfirmation)
//            logger?.v(.provisioning, "Sending \(provisioningConfirmation)")
//            try send(provisioningConfirmation)
//        } catch {
//            state = .fail(error)
//        }
    }
    
    /// Resets the provisioning properties and state.
    func reset() {
        authenticationMethod = nil
//        provisioningCapabilities = nil
        provisioningData = nil
//        state = .ready
    }
    
}

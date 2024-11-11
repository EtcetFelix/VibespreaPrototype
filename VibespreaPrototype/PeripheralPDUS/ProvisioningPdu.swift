//
//  ProvisioningPdu.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/23/22.
//

import Foundation
import nRFMeshProvision

internal typealias ProvisioningPdu = Data

internal enum ProvisioningPduType: UInt8 {
    case invite        = 0
    case capabilities  = 1
    case start         = 2
    case publicKey     = 3
    case inputComplete = 4
    case confirmation  = 5
    case random        = 6
    case data          = 7
    case complete      = 8
    case failed        = 9
    
    var type: UInt8 {
        return rawValue
    }
}

internal struct ProvisioningRequest {
    let type: ProvisioningPduType
    let publicKey: Data?
    let authenticationMethod: AuthenticationMethod?
    let confirmation: Data?
    let random: Data?
    
    init?(_ data: Data) {
        print("Dumping data")
        dump(data)
        print("data[0]: \(data[0])")
        guard data.count > 0, let pduType = ProvisioningPduType(rawValue: data[0]) else {
            return nil
        }
        self.type = pduType
        
        switch pduType {
        case .invite:
            publicKey = nil
            authenticationMethod = nil
            confirmation = nil
            random = nil
        case .start:
            // TODO: change this to its own class that holds all the values
            let authenticationMethodByte = data[2]
            let authenticationActionByte = data[3]
            let authenticationSizeByte = data[4]
            // Set the authentication method to the correct enum based on the raw data byte value
            switch authenticationMethodByte {
            case 0:
                authenticationMethod = .noOob
            case 1:
                authenticationMethod = .staticOob
            case 2:
                // Ensure the output action is valid before creating the authentication method
                guard authenticationActionByte < 5 else {
                    print("Output action is not valid as of mesh specification 1.1")
                    return nil
                }
                authenticationMethod = .outputOob(action: OutputAction(rawValue: authenticationActionByte)!, size: authenticationSizeByte)
            case 3:
                // Ensure the input action is valid before creating the authentication method
                guard authenticationActionByte < 4 else {
                    print("Input action is not valid as of mesh specification 1.1")
                    return nil
                }
                authenticationMethod = .inputOob(action: InputAction(rawValue: authenticationActionByte)!, size: authenticationSizeByte)
            default:
                print("Autheticatio method not understood")
                return nil
            }
            publicKey = nil
            confirmation = nil
            random = nil
        case .publicKey:
            print("PROVISIONING PDU: public key pdu")
            publicKey = data.subdata(in: 1..<data.count)
            authenticationMethod = nil
            confirmation = nil
            random = nil
        case .confirmation:
            print("PROVISIONING PDU: confirmation pdu")
            publicKey = nil
            authenticationMethod = nil
            confirmation = data.subdata(in: 1..<data.count)
            random = nil
        case .random:
            print("PROVISIONING PDU: random pdu")
            publicKey = nil
            authenticationMethod = nil
            confirmation = nil
            random = data.subdata(in: 1..<data.count)
        case .data:
            print("PROVISIONING PDU: data pdu")
            publicKey = nil
            authenticationMethod = nil
            confirmation = nil
            random = nil
        default:
            print("PROVISIONING PDU: Unkown pdu type")
            publicKey = nil
            authenticationMethod = nil
            confirmation = nil
            random = nil
        }
        
    }

    
}

internal enum ProvisioningResponse {
    case capabilities(numberOfElements: UInt8,
                      algorithms: Algorithms,
                      publicKeyType: PublicKeyType,
                      staticOobType:  StaticOobType,
                      outputOobSize: UInt8,
                      outputOobActions: OutputOobActions,
                      inputOobSize: UInt8,
                      inputOobActions: InputOobActions)
    case publicKey(_ key: Data)
    case confirmation(_ data: Data)
    case random(_ data: Data)
    case provisioningComplete
    
    var pdu: ProvisioningPdu {
        switch self {
        case let .capabilities(numberOfElements: numberOfElements, algorithms: algorithms,
                               publicKeyType: publicKeyType, staticOobType: staticOobType,
                               outputOobSize: outputOobSize, outputOobActions: outputOobActions,
                               inputOobSize: inputOobSize, inputOobActions: inputOobActions):
            var capabilitiesPDU = Data(pdu: .capabilities)
            capabilitiesPDU = capabilitiesPDU.with(ProvisioningPduType.capabilities.type)
            capabilitiesPDU = capabilitiesPDU.with(numberOfElements)
            capabilitiesPDU = capabilitiesPDU.with(CFSwapInt16(algorithms.rawValue))
            capabilitiesPDU = capabilitiesPDU.with(publicKeyType.rawValue)
            capabilitiesPDU = capabilitiesPDU.with(staticOobType.rawValue)
            capabilitiesPDU = capabilitiesPDU.with(outputOobSize)
            capabilitiesPDU = capabilitiesPDU.with(CFSwapInt16(outputOobActions.rawValue))
            capabilitiesPDU = capabilitiesPDU.with(inputOobSize)
            capabilitiesPDU = capabilitiesPDU.with(CFSwapInt16(inputOobActions.rawValue))
            return capabilitiesPDU
        case let .publicKey(key):
            var data = ProvisioningPdu(pdu: .publicKey)
            data += key
            return data
        case let .confirmation(confirmation):
            var data = ProvisioningPdu(pdu: .confirmation)
            data += confirmation
            return data
        case let .random(random):
            var data = ProvisioningPdu(pdu: .random)
            data += random
            return data
        case .provisioningComplete:
            var data = ProvisioningPdu(pdu: .complete)
            return data
        }
    }
}

private extension Data {
    
    init(pdu: ProvisioningPduType) {
        self = Data([pdu.type])
    }
    
    mutating func with(_ parameter: UInt8) -> Data {
        self.append(parameter)
        return self
    }
    
    mutating func with(_ parameter: UInt16) -> Data {
        self.append(parameter.data)
        return self
    }
    
}

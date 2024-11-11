//
//  ProvisioningCapabilitesPdu.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/22/22.
//

import Foundation
import nRFMeshProvision


/// The peripheral device sends this PDU to indicate its supported provisioning
/// capabilities to a Provisioner.
public struct ProvisioningCapabilitiesPdu {
    // The pdu that will be returned after init
    var capabilitiesPDU: Data!
    /// Number of elements supported by the device.
    public let numberOfElements: UInt8
    /// Supported algorithms and other capabilities.
    public let algorithms:       Algorithms
    /// Supported public key types.
    public let publicKeyType:    PublicKeyType
    /// Supported static OOB Types.
    public let staticOobType:    StaticOobType
    /// Maximum size of Output OOB supported.
    public let outputOobSize:    UInt8
    /// Supported Output OOB Actions.
    public let outputOobActions: OutputOobActions
    /// Maximum size of Input OOB supported.
    public let inputOobSize:     UInt8
    /// Supported Input OOB Actions.
    public let inputOobActions:  InputOobActions
    
    init?(numberOfElements: UInt8, algorithms: Algorithms, publicKeyType: PublicKeyType, staticOobType: StaticOobType,
          outputOobSize: UInt8, outputOobActions: OutputOobActions, inputOobSize: UInt8,
          inputOobActions: InputOobActions){
        self.numberOfElements = numberOfElements
        self.algorithms       = algorithms
        self.publicKeyType    = publicKeyType
        self.staticOobType    = staticOobType
        self.outputOobSize    = outputOobSize
        self.outputOobActions = outputOobActions
        self.inputOobSize     = inputOobSize
        self.inputOobActions  = inputOobActions
        
        capabilitiesPDU = Data(pdu: .capabilities)
//        capabilitiesPDU = capabilitiesPDU.with(ProvisioningPduType.capabilities.type)
        capabilitiesPDU = capabilitiesPDU.with(self.numberOfElements)
        capabilitiesPDU = capabilitiesPDU.with(CFSwapInt16(self.algorithms.rawValue))
        capabilitiesPDU = capabilitiesPDU.with(self.publicKeyType.rawValue)
        capabilitiesPDU = capabilitiesPDU.with(self.staticOobType.rawValue)
        capabilitiesPDU = capabilitiesPDU.with(self.outputOobSize)
        capabilitiesPDU = capabilitiesPDU.with(CFSwapInt16(self.outputOobActions.rawValue))
        capabilitiesPDU = capabilitiesPDU.with(self.inputOobSize)
        capabilitiesPDU = capabilitiesPDU.with(CFSwapInt16(self.inputOobActions.rawValue))
    }
    
        
}

extension ProvisioningCapabilitiesPdu: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return """
        Number of elements: \(numberOfElements)
        Algorithms: \(algorithms)
        Public Key Type: \(publicKeyType)
        Static OOB Type: \(staticOobType)
        Output OOB Size: \(outputOobSize)
        Output OOB Actions: \(outputOobActions)
        Input OOB Size: \(inputOobSize)
        Input OOB Actions: \(inputOobActions)
        """
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

//
//  MeshNetworkNewModel.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/26/22.
//

import Foundation
import nRFMeshProvision

/// The Bluetooth Mesh Network configuration.
///
/// The mesh network object contains information about known Nodes, Provisioners,
/// Network and Application Keys, Groups and Scenes, as well as the exclusion list.
/// The configuration does not contain any sequence numbers, IV Index, or other
/// network properties that change without the action from the Provisioner.
///
/// The structire of this class is compatible with Mesh Configuration Database 1.0.1.
public class MeshNetworkNewDevice: Codable {
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    public let uuid: UUID
    /// The last time the Provisioner database has been modified.
    public internal(set) var timestamp: Date
    /// Whether the configuration contains full information about the mesh network,
    /// or only partial. In partial configuration Nodes' Device Keys can be `nil`.
    public let isPartial: Bool
    /// UTF-8 string, which should be human readable name for this mesh network.
    public var meshName: String {
        didSet {
            timestamp = Date()
        }
    }
    /// An array of provisioner objects that includes information about known
    /// Provisioners and ranges of addresses and scenes that have been allocated
    /// to these Provisioners.
    public internal(set) var provisioners: [Provisioner]
    /// An array that include information about Network Keys used in the
    /// network.
    public internal(set) var networkKeys: [NetworkKey]
    /// An array that include information about Application Keys used in the
    /// network.
    public internal(set) var applicationKeys: [ApplicationKey]
    /// An array of Nodes in the network.
    public internal(set) var nodes: [Node]
    /// An array of Groups in the network.
    public internal(set) var groups: [Group]
    /// An array of Scenes in the network.
    public internal(set) var scenes: [Scene]
    /// An array containing Unicast Addresses that cannot be assigned to new Nodes.
    internal var networkExclusions: [String]?

    internal init?(name: String, uuid: UUID = UUID(), provisioner: Provisioner, keyIndex: KeyIndex, key: Data) {
        guard keyIndex.isValidKeyIndex else {
            return nil
        }
        self.uuid              = uuid
        self.meshName          = name
        self.isPartial         = false
        self.timestamp         = Date()
        self.provisioners      = [provisioner]
        // accept a network key
        self.networkKeys       = [try! NetworkKey(name: name, index: keyIndex, key: key)]
        self.applicationKeys   = []
        self.nodes             = []
        self.groups            = []
        self.scenes            = []
        self.networkExclusions = []
    }

    // MARK: - Codable

    /// Coding keys used to export / import Mesh Network.
    enum CodingKeys: String, CodingKey {
        case schema          = "$schema"
        case id
        case version
        case uuid            = "meshUUID"
        case isPartial       = "partial"
        case meshName
        case timestamp
        case provisioners
        case networkKeys     = "netKeys"
        case applicationKeys = "appKeys"
        case nodes
        case groups
        case scenes
        case networkExclusions
    }

    
    public required init(from decoder: Decoder) throws {
        self.uuid              = UUID()
        self.meshName          = ""
        self.isPartial         = false
        self.timestamp         = Date()
        self.provisioners      = []
        self.networkKeys       = []
        self.applicationKeys   = []
        self.nodes             = []
        self.groups            = []
        self.scenes            = []
        self.networkExclusions = []
    }

    public func encode(to encoder: Encoder) throws {
        let schema = "http://json-schema.org/draft-04/schema#"
        let id = "http://www.bluetooth.com/specifications/assigned-numbers/mesh-profile/cdb-schema.json#"
        let version = "1.0.0"

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schema, forKey: .schema)
        try container.encode(id, forKey: .id)
        try container.encode(version, forKey: .version)

        try container.encode(uuid, forKey: .uuid)
        try container.encode(isPartial, forKey: .isPartial)
        try container.encode(meshName, forKey: .meshName)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(provisioners, forKey: .provisioners)
        try container.encode(networkKeys, forKey: .networkKeys)
        try container.encode(applicationKeys, forKey: .applicationKeys)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(groups, forKey: .groups)
        try container.encode(scenes, forKey: .scenes)
        try container.encodeIfPresent(networkExclusions, forKey: .networkExclusions)
    }

}

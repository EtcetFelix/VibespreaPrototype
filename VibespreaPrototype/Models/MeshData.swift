//
//  MeshData.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/26/22.
//

import Foundation
import nRFMeshProvision

/// The Mesh Network configuration saved internally.
/// It contains the Mesh Network and additional data that
/// are not in the JSON schema, but are used by in the app.
internal class MeshData: Codable {
    /// Mesh Network state.
    public internal(set) var meshNetwork: MeshNetwork?
}

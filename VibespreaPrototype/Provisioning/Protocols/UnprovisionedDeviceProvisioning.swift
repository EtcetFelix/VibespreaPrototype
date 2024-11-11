//
//  UnprovisionedDeviceDelegate.swift
//  VibespreaPrototype
//
//  Created by Alan Bohannon on 12/28/22.
//

import Foundation

protocol UnprovisionedDeviceProvisioning {
    
    func didReceiveProvisioningData(data: Data)
}

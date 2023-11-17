//
//  Item.swift
//  DondeGas
//
//  Created by Sergio Frejo on 17/11/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

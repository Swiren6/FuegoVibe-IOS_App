//
//  Item.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
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

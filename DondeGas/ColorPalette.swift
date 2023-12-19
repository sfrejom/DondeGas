//
//  ColorPalette.swift
//  DondeGas
//
//  Created by Sergio Frejo on 28/11/23.
//

import Foundation
import SwiftUI

struct ColorPalette {
    @Environment(\.colorScheme) var colorScheme
    
    public var backgroundColor: Color {
        switch colorScheme {
        case .light:
            return Color.black.opacity(0.55) // Blanco semitransparente para tema claro
        case .dark:
            return Color.black.opacity(0.55) // Negro semitransparente para tema oscuro
        @unknown default:
            return Color.gray.opacity(0.55) // Por defecto, si se añaden más modos en el futuro
        }
    }

    public let tangerine = Color(red: 0.9255, green: 0.5608, blue: 0.3686)
    public let mango = Color(red: 0.9529, green: 0.7137, blue: 0.3922)
    public let sunburst = Color(red: 0.9009, green: 0.3863, blue: 0.2176)
    public let sand = Color(red: 0.9843, green: 0.8667, blue: 0.6157)
    public let hotSand = Color(red: 0.9137, green: 0.7490, blue: 0.3490)
    public let softGreen = Color(red: 0.6235, green: 0.7333, blue: 0.4510)
    public let softerGreen = Color(red: 0.7482, green: 0.88, blue: 0.5412)
    public let greenishBlue = Color(red: 0.4784, green: 0.6510, blue: 0.7137)
    
}

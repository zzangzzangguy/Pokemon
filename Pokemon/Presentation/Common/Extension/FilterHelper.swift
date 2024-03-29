//
//  Filter.swift
//  Pokemon
//
//  Created by 김기현 on 3/28/24.
//

import Foundation

enum FilterHelper {
    static func filterRarities(_ selectedRarity: String) -> [String] {
        switch selectedRarity {
        case "Common":
            return ["Common"]
        case "Uncommon":
            return ["Uncommon"]
        case "Rare":
            return ["Rare", "Rare Holo", "Rare Prime", "Rare Prism Star", "Rare Holo EX", "Rare Holo GX", "Rare Holo LV.X", "Rare Holo V", "Rare Holo VMAX", "Rare Rainbow", "Rare Shining", "Rare Secret", "Rare Shiny", "Rare Shiny GX"]
        default:
            return []
        }
    }
}

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
            return ["Promo",
                    "Rare",
                    "Rare ACE",
                    "Rare BREAK",
                    "Rare Holo",
                    "Rare Holo EX",
                    "Rare Holo GX",
                    "Rare Holo LV.X",
                    "Rare Holo Star",
                    "Rare Holo V",
                    "Rare Holo VMAX",
                    "Rare Prime",
                    "Rare Prism Star",
                    "Rare Rainbow",
                    "Rare Secret",
                    "Rare Shining",
                    "Rare Shiny",
                    "Rare Shiny GX",
                    "Rare Ultra",
            "LEGEND"]
        default:
            return []
        }
    }
}

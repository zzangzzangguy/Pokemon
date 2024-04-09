//
//  CardListSection.swift
//  Pokemon
//
//  Created by 강호성 on 2/19/24.
//

import Foundation
import RxDataSources

typealias CardListItems = [PokemonCard]

struct CardListSection {

    typealias CardListSectionModel = SectionModel<Int, CardListItems>

    enum CardListItems: Equatable {
        case firstItem(PokemonCard)
    }
}

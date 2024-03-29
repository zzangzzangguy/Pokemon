//
//  FavoriteService.swift
//  Pokemon
//
//  Created by 김기현 on 3/26/24.
//

import Foundation
import ReactorKit

class AppState {
    static let shared = AppState()
    let favoriteStatusChanged = PublishSubject<String>()
}

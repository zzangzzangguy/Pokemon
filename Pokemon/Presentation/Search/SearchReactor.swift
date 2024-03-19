import ReactorKit
import RxSwift
import RealmSwift
import Realm

class SearchReactor: Reactor {
    enum Action {
        case updateSearchQuery(String)
        case search(String)
        case loadNextPage
        case scrollTop
        case updateFavoriteStatus(String, Bool)
        case selectItem(PokemonCard)
        case selectRarity(String)

    }

    enum Mutation {
        case setQuery(String)
        case setSearchResults([PokemonCard])
        case appendSearchResults([PokemonCard])
        case setLoading(Bool)
        case setCanLoadMore(Bool)
        case setNoResults(Bool)
        case setScrollTop(Bool)
        case setFavorite(String, Bool)
        case setSelectedItem(PokemonCard?)
        case setSelectedRarity(String)

    }

    struct State {
        var query: String = ""
        var searchResult: [PokemonCard] = []
        var isLoading: Bool = false
        var canLoadMore: Bool = true
        var noResults: Bool = false
        var scrollTop: Bool = false
        var favorites: [String] = []
        var selectedItem: PokemonCard?
        var selectedRarity: String = "All"

    }

    var initialState = State()
    private let pokemonRepository: PokemonRepositoryType

    // MARK: - Initialization
    init(pokemonRepository: PokemonRepositoryType) {
        self.pokemonRepository = pokemonRepository

        let favoriteCardIDs = RealmManager.shared.getFavoriteCardIDs()
        initialState = State(favorites: favoriteCardIDs)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSearchQuery(let query):
            return .concat([
                .just(.setQuery(query)),
                .just(.setNoResults(false))
            ])

        case .search(let query):
            guard !query.isEmpty else {
                return .concat([
                    .just(.setLoading(false)),
                    .just(.setSearchResults([])),
                    .just(.setNoResults(true))
                ])
            }

            let initialPage = 1
            return .concat([
                .just(.setLoading(true)),
                searchQuery(query: query, page: initialPage)
                    .map { results in
                        if results.isEmpty {
                            return .setNoResults(true)
                        } else {
                            return .setSearchResults(results)
                        }
                    },
                .just(.setLoading(false))
            ])

        case .loadNextPage:
            guard !currentState.isLoading, currentState.canLoadMore else {
                return .empty()
            }

            let nextPage = (currentState.searchResult.count / 20) + 1

            return .concat([
                .just(.setLoading(true)),
                searchQuery(query: currentState.query, page: nextPage)
                    .map { .appendSearchResults($0) },
                .just(.setLoading(false)),
                .just(.setCanLoadMore(true))
            ])

        case .scrollTop:
            return .concat([
                .just(.setScrollTop(true)),
                .just(.setScrollTop(false))
            ])

        case .updateFavoriteStatus(let cardID, let isFavorite):
            return Observable.create { [weak self] observer in
                guard let self = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }
                RealmManager.shared.updateFavorite(for: cardID, isFavorite: isFavorite)
                observer.onNext(Mutation.setFavorite(cardID, isFavorite))
                observer.onCompleted()
                return Disposables.create()
            }
        case .selectItem(let card):
            return Observable.just(Mutation.setSelectedItem(card))
        case .selectRarity(let rarity):
            return Observable.just(Mutation.setSelectedRarity(rarity))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setQuery(let query):
            newState.query = query

        case .setSearchResults(let result):
            newState.searchResult = result
            newState.canLoadMore = true

        case .appendSearchResults(let results):
            newState.searchResult += results

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setCanLoadMore(let canLoadMore):
            newState.canLoadMore = canLoadMore

        case .setNoResults(let noResults):
            newState.noResults = noResults

        case .setScrollTop(let scrollToTop):
            newState.scrollTop = scrollToTop

        case .setFavorite(let cardID, let isFavorite):
            if isFavorite {
                newState.favorites.append(cardID)
            } else {
                if let index = newState.favorites.firstIndex(of: cardID) {
                    newState.favorites.remove(at: index)
                }
            }

        case .setSelectedItem(let item):
            newState.selectedItem = item
        case .setSelectedRarity(let rarity):
            newState.selectedRarity = rarity
        }

        return newState
    }




    private func searchQuery(query: String, page: Int) -> Observable<[PokemonCard]> {
        let pageSize = 20
        var rarities: [String] = []
        switch currentState.selectedRarity {
        case "Common":
            rarities = ["Common"]
        case "Uncommon":
            rarities = ["Uncommon"]
        case "Rare":
            rarities = ["Rare", "Rare Holo", "Rare Prime", "Rare Prism Star"]
        case "Ultra Rare":
            rarities = ["Rare Holo EX", "Rare Holo GX", "Rare Holo LV.X", "Rare Holo V", "Rare Holo VMAX", "Rare Rainbow", "Rare Shining"]
        case "Secret Rare":
            rarities = ["Rare Secret", "Rare Shiny", "Rare Shiny GX"]
        default:
            rarities = []
        }
        let request = CardsRequest(query: query, page: page, pageSize: pageSize, rarities: rarities)

        return Observable.create { observer in
            self.pokemonRepository.fetchCards(request: request) { result in
                switch result {
                case .success(let response):
                    observer.onNext(response.data)
                case .failure:
                    observer.onNext([])
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

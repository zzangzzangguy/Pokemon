//
//  FavoriteViewController.swift
//  Pokemon
//
//  Created by 김기현 on 3/21/24.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import RealmSwift
import SnapKit
import Then

class FavoriteViewController: BaseViewController, ReactorKit.View {
    let filterControl = UISegmentedControl(items: ["All", "Common", "Uncommon", "Rare"]).then {
        $0.selectedSegmentIndex = 0
    }

    let tableView = UITableView().then {
        $0.register(PokemonCardTableViewCell.self, forCellReuseIdentifier: "PokemonCardTableViewCell")
        $0.rowHeight = 180
    }

    required init(reactor: FavoriteReactor) {
        super.init()
        self.reactor = reactor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reactor?.action.onNext(.loadFavorites)
    }

    private func setupUI() {
        view.addSubview(filterControl)
        view.addSubview(tableView)

        filterControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(filterControl.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    func bind(reactor: FavoriteReactor) {
        filterControl.rx.selectedSegmentIndex
            .map { index -> String in
                let rarity = self.filterControl.titleForSegment(at: index) ?? ""
                return rarity
            }
            .distinctUntilChanged()
            .map(Reactor.Action.filterFavorites)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map { state -> [PokemonCard] in
                let selectedRarity = state.selectedRarity
                return state.favoriteCards
                    .filter { selectedRarity == "All" || $0.rarity == selectedRarity }
                    .map { $0.toPokemonCard() }
            }
            .distinctUntilChanged()
            .bind(to: tableView.rx.items(cellIdentifier: PokemonCardTableViewCell.reuseIdentifier, cellType: PokemonCardTableViewCell.self)) { index, card, cell in
                cell.configure(with: card, isFavorite: true)

                cell.favoriteButton.rx.tap
                    .map { Reactor.Action.toggleFavorite(card.id, !isFavorite) }
                    .bind(to: self.reactor!.action)
                    .disposed(by: cell.disposeBag)

            }
            .disposed(by: disposeBag)
        

        reactor.state
            .map { $0.selectedRarity }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak tableView] _ in tableView?.reloadData() })
            .disposed(by: disposeBag)

        RealmManager.shared.favoriteUpdates
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.reactor?.action.onNext(.loadFavorites) })
            .disposed(by: disposeBag)


    }
}

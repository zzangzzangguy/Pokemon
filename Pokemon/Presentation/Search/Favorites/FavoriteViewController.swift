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
        $0.register(PokemonCardTableViewCell.self, forCellReuseIdentifier: PokemonCardTableViewCell.reuseIdentifier)
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

        reactor.state.map { $0.filteredFavorites }
            .distinctUntilChanged() // 상태 변화 시에만 UI 업데이트
            .observe(on: MainScheduler.instance)
            .do(onNext: { [weak self] _ in
                        print("FavoriteViewController - Table view updated with new data")
                    })
            .bind(to: tableView.rx.items(cellIdentifier: PokemonCardTableViewCell.reuseIdentifier, cellType: PokemonCardTableViewCell.self)) { [weak self] index, card, cell in
                guard let self = self else { return }
                cell.configure(with: card.toPokemonCard(), isFavorite: true)
                cell.favoriteButton.rx.tap
                    .subscribe(onNext: { [weak self, weak cell] _ in
                        guard let `self` = self, let cell = cell else { return }
                        let isFavorite = !cell.favoriteButton.isSelected
                        cell.favoriteButton.isSelected = isFavorite
                        self.reactor?.action.onNext(.toggleFavorite(card.id, isFavorite))
                    })
                    .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)



        reactor.viewSubject
            .observe(on: MainScheduler.instance)
              .subscribe(onNext: { [weak self] mutation in
                  switch mutation {
                  case .setFavorites(_):
                      break
                  case .setSelectedRarity(_):
                      break
                  case .reloadTableView:
                            print("FavoriteViewController - reloadTableView")
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                  case .setFilteredFavorites(_):
                      break
                  }
              })
              .disposed(by: disposeBag)
//                print("FavoriteViewController - tableView reloadData() called")



    }
}

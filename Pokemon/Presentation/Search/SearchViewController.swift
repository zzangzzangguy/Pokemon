//
//  SearchViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import ReactorKit

final class SearchViewController: BaseViewController, UISearchBarDelegate {


    // MARK: - Properties
    private var tableView: UITableView?
    private var searchBar: UISearchBar?

    var reactor: SearchReactor?


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setConstraints()
        setConfiguration()

        let repository = PokemonRepository() 
           let reactor = SearchReactor(pokemonRepository: repository)
           self.reactor = reactor

           bind(reactor: reactor)
       }

    func bind(reactor: SearchReactor) {
        
        guard let searchBar = searchBar else { return }
        guard let tableView = tableView else { return }

        searchBar.rx.text.orEmpty
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map { SearchReactor.Action.updateSearchQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .map { SearchReactor.Action.search }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)


        searchBar.rx.textDidEndEditing
            .map { SearchReactor.Action.search }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)



        reactor.state
            .map { $0.searchResult }
            .compactMap { result -> [PokemonCard]? in
                if case let .success(pokemonCards) = result {
                    return pokemonCards
                } else {
                    return nil
                }
            }
            .map { [SectionModel(model: "", items: $0)] }
            .bind(to: tableView.rx.items(dataSource: dataSource()))
            .disposed(by: disposeBag)
    }

    // MARK: - Helpers

    override func setView() {
        super.setView()

        searchBar = UISearchBar()
        searchBar?.placeholder = " 포켓몬을 검색하세요!"
        navigationItem.titleView = searchBar
        searchBar?.delegate = self

        tableView = UITableView()
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        if let tableView = tableView {
            view.addSubview(tableView)
        }
    }

    override func setConstraints() {
        super.setConstraints()

        if let tableView = tableView {
              tableView.snp.makeConstraints {
                  $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                  $0.left.right.bottom.equalToSuperview()
              }
          }
      }
    private func dataSource() -> RxTableViewSectionedReloadDataSource<SectionModel<String, PokemonCard>> {
        return RxTableViewSectionedReloadDataSource<SectionModel<String, PokemonCard>>(
            configureCell: { _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = item.name
                return cell
            }
        )
    }

    override func setConfiguration() {
        super.setConfiguration()
    }
}

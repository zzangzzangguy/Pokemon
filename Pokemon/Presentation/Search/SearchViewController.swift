//
//  SearchViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources
import ReactorKit

final class SearchViewController: BaseViewController, UISearchBarDelegate {


    // MARK: - Properties
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private var loadingIndicator: UIActivityIndicatorView!
    private var hasSearched = false
    var reactor: SearchReactor?


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setConstraints()
        setConfiguration()
        initReactor()
    }
    private func initReactor() {
        self.reactor = SearchReactor(pokemonRepository: PokemonRepository())
        if let reactor = self.reactor {
            bind(reactor: reactor)
        }
    }

    private func bind(reactor: SearchReactor) {

        searchBar.rx.text.orEmpty
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map { SearchReactor.Action.updateSearchQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
              .do(onNext: { [weak self] _ in
                  self?.showLoadingIndicator()
                  self?.hasSearched = true
                  print("검색")
              })
              .map { SearchReactor.Action.search }
              .bind(to: reactor.action)
              .disposed(by: disposeBag)



        searchBar.rx.textDidEndEditing
            .map { SearchReactor.Action.search }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)


        // State 에서 View 로

        reactor.state
                .map { $0.searchResult }
                .filter { _ in self.hasSearched }
                .subscribe(onNext: { [weak self] result in
                    DispatchQueue.main.async {
                                      self?.hideLoadingIndicator()
                                  }
                    switch result {
                    case .success(let pokemonCards):
                        self?.hasSearched = false
                        if pokemonCards.isEmpty {
                            self?.showNoResultsAlert()
                        } else {
                            let sectionModel = [SectionModel(model: "", items: pokemonCards)]
                            Observable.just(sectionModel)
                                .bind(to: self!.tableView.rx.items(dataSource: self!.dataSource()))
                                .disposed(by: self!.disposeBag)
                        }
                    case .failure(let error):
                        print("검색 실패: \(error)")

                        self?.hasSearched = false
                        self?.showNoResultsAlert()
                    default:
                        break
                    }
                })
                .disposed(by: disposeBag)
        }
    


    // MARK: - Helpers

    override func setView() {
        super.setView()

        searchBar.placeholder = " 포켓몬을 검색하세요!"
        navigationItem.titleView = searchBar
        searchBar.delegate = self

        tableView.register(PokemonCardTableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.delegate = self

        loadingIndicator = UIActivityIndicatorView(style: .large)
               loadingIndicator.color = .black
               view.addSubview(loadingIndicator)
           }
    


    override func setConstraints() {
        super.setConstraints()
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func dataSource() -> RxTableViewSectionedReloadDataSource<SectionModel<String, PokemonCard>> {
        return RxTableViewSectionedReloadDataSource<SectionModel<String, PokemonCard>>(
            configureCell: { _, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PokemonCardTableViewCell
                cell.configure(with: item)
                return cell
            }
        )
        
    }
    private func showLoadingIndicator() {
           loadingIndicator.startAnimating()
           loadingIndicator.isHidden = false
       }

       private func hideLoadingIndicator() {
           loadingIndicator.stopAnimating()
           loadingIndicator.isHidden = true
       }

       private func showNoResultsAlert() {
           let alertController = UIAlertController(title: "검색 결과 없음", message: "입력한 검색어에 해당하는 포켓몬이 없음.", preferredStyle: .alert)
           alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
           present(alertController, animated: true, completion: nil)
       }

    override func setConfiguration() {
        super.setConfiguration()
        tableView.delegate = self
    }
}
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180

    }
}

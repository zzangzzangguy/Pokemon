//
//  SearchViewController.swift
//  Pokemon
//
//  Created by 강호성 on 2/15/24.
//

// SearchViewController.swift
import UIKit
import SnapKit
import RxSwift
import RxCocoa
//import RxDataSources
import ReactorKit

final class SearchViewController: BaseViewController, ReactorKit.View {
    // MARK: - Properties
    private let FilterControl = UISegmentedControl(items: ["All", "Common", "Uncommon", "Rare"]).then {
        $0.selectedSegmentIndex = 0
    }
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        return indicator.then {
            $0.color = .black
            $0.hidesWhenStopped = true
        }
    }()
    private lazy var scrollToTopButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 25
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.3
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }
    
    // MARK: - Initialization
    required init(reactor: SearchReactor) {
        super.init()
        self.reactor = reactor
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setConstraints()
        setConfiguration()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reactor?.action.onNext(.loadFavorites)
    }
    
    // MARK: - Binding
    func bind(reactor: SearchReactor) {
        // Action
        searchController.searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { Reactor.Action.updateSearchQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        searchController.searchBar.rx.searchButtonClicked
            .withLatestFrom(searchController.searchBar.rx.text.orEmpty)
            .filter { !$0.isEmpty }
            .map { Reactor.Action.search($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        tableView.rx.contentOffset
            .filter { [weak self] offset in
                guard let self = self else { return false }
                return offset.y + self.tableView.frame.height >= self.tableView.contentSize.height - 100
            }
            .map { _ in Reactor.Action.loadNextPage }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        scrollToTopButton.rx.tap
            .map { Reactor.Action.scrollTop }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // State
        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        reactor.state
            .map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isHidden)
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.searchResult }
            .distinctUntilChanged()
            .bind(to: tableView.rx.items(
                cellIdentifier: PokemonCardTableViewCell.reuseIdentifier,
                cellType: PokemonCardTableViewCell.self)) { [weak self] _, item, cell in
                    guard let self = self else { return }
                    let isFavorite = RealmManager.shared.getCard(withId: item.id)?.isFavorite ?? false
//                    print("셀 구성 - 이름: \(item.name), HP: \(item.hp ?? "-"), isFavorite: \(isFavorite)")

                    cell.configure(with: item, isFavorite: isFavorite)
                    cell.favoriteButton.rx.tap
                        .subscribe(onNext: { [weak self, weak cell] _ in
                            guard let `self` = self, let cell = cell else { return }
                            let isFavorite = !cell.favoriteButton.isSelected
                            cell.favoriteButton.isSelected = isFavorite
                            print("즐겨찾기 상태 변경됨 - 이름: \(item.name), 타입: \(item.types?.joined(separator: ", ") ?? "-"), 등급: \(item.rarity ?? "-"), HP: \(item.hp ?? "N/A")")

                            self.reactor?.action.onNext(.updateFavoriteStatus(item.id, isFavorite))
                        })
                        .disposed(by: cell.disposeBag)
            }
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.noResults }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
        
            .filter { $0 == true }
            .bind(onNext: { [weak self] noResults in
                if noResults {
                    self?.searchController.searchBar.resignFirstResponder()
                    self?.showNoResultsAlert()
                }
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.scrollTop }
            .distinctUntilChanged()
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
            .disposed(by: disposeBag)
        reactor.state
            .map { $0.selectedItem }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] selectedItem in
                let detailVC = CardDetailViewController(card: selectedItem)
                self?.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
        reactor.state
            .map { $0.favorites }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        tableView.rx.contentOffset
            .map { $0.y < 100 }
            .distinctUntilChanged()
            .bind(to: scrollToTopButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        FilterControl.rx.selectedSegmentIndex
            .map { index -> String in
                let rarity = self.FilterControl.titleForSegment(at: index) ?? ""
                return rarity
            }
            .distinctUntilChanged()
            .map { Reactor.Action.selectRarity($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
    }
    
    // MARK: - Helpers
    override func setView() {
        super.setView()
        searchController.searchBar.placeholder = " 포켓몬을 검색하세요!"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        tableView.delegate = nil
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(scrollToTopButton)
        view.addSubview(FilterControl)
    }
    override func setConstraints() {
        super.setConstraints()
        tableView.snp.makeConstraints {
            $0.top.equalTo(FilterControl.snp.bottom).offset(8)
            $0.left.right.bottom.equalToSuperview()
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        scrollToTopButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            $0.width.height.equalTo(50)
        }
        FilterControl.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    override func setConfiguration() {
        super.setConfiguration()
        tableView.register(PokemonCardTableViewCell.self,
                           forCellReuseIdentifier: PokemonCardTableViewCell.reuseIdentifier)
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.spellCheckingType = .no
    }
    private func showNoResultsAlert() {
        let alertController = UIAlertController(title: "검색 결과 없음", message: "입력한 검색어에 해당하는 포켓몬이 없습니다.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    private func showErrorAlert(message: String) {
        let alertController = UIAlertController(title: "에러", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedItem = reactor?.currentState.searchResult[indexPath.row] else {
            return
        }
        
        let detailVC = CardDetailViewController(card: selectedItem)
              detailVC.favoriteStatusChanged
                  .subscribe(onNext: { [weak self] isFavorite in
                      guard let self = self else { return }
                      self.reactor?.action.onNext(.updateFavoriteStatus(selectedItem.id, isFavorite))
                  })
                  .disposed(by: disposeBag)

              navigationController?.pushViewController(detailVC, animated: true)
          }
      }

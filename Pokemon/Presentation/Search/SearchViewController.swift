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

final class SearchViewController: BaseViewController {


    // MARK: - Properties
    private var tableView: UITableView!
    private var searchBar: UISearchBar!

    var reactor: SearchReactor!


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setView()
        setConstraints()
        setConfiguration()
    }

    // MARK: - Helpers

    override func setView() {
        super.setView()

        searchBar = UISearchBar()
        searchBar.placeholder = " 포켓몬을 검색하세요!"
        navigationItem.titleView = searchBar

        tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)

    }

    override func setConstraints() {
        super.setConstraints()

        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.left.right.bottom.equalToSuperview()
        }
    }

    override func setConfiguration() {
        super.setConfiguration()
    }
}

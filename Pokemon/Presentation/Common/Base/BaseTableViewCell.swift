//
//  BaseTableViewCell.swift
//  Pokemon
//
//  Created by 강호성 on 2/18/24.
//

import UIKit
import RxSwift

class BaseTableViewCell<T>: UITableViewCell {

    // MARK: - Properties

    var disposeBag = DisposeBag()

    var model: T? {
        didSet {
            if let model = model {
                bind(model)
            }
        }
    }

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setView()
        setConstraints()
        setConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    func setView() {}
    func setConstraints() {}
    func setConfiguration() {
        selectionStyle = .none
    }

    func bind(_ model: T?) {}
}

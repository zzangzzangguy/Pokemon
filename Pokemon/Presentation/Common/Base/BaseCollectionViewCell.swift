//
//  BaseCollectionViewCell.swift
//  Pokemon
//
//  Created by 강호성 on 2/18/24.
//

import UIKit.UICollectionViewCell
import RxSwift

class BaseCollectionViewCell<T>: UICollectionViewCell {

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setView()
        setConstraints()
        setConfiguration()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    func setView() {}
    func setConstraints() {}
    func setConfiguration() {}

    func bind(_ model: T?) {}
}

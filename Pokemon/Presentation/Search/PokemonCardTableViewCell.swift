//
//  PokemonCardTableViewCell.swift
//  Pokemon
//
//  Created by 김기현 on 2/24/24.
//

// PokemonCardTableViewCell.swift
// PokemonCardTableViewCell.swift
import UIKit
import Kingfisher
import Then
import SnapKit
import RxSwift
import RxCocoa
import RealmSwift

class PokemonCardTableViewCell: UITableViewCell {
    lazy var disposeBag = DisposeBag()
    var favoriteButtonTapped = PublishSubject<Bool>()
    private var cardInfo: PokemonCard?

    let cardImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    let nameLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
    }

    let hpLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .red
    }

    let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "star"), for: .normal)
        $0.setImage(UIImage(systemName: "star.fill"), for: .selected)
        $0.tintColor = .systemYellow
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    private func setupView() {
        contentView.addSubview(cardImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(hpLabel)
        contentView.addSubview(favoriteButton)
    }

    private func setupLayout() {
        cardImageView.snp.makeConstraints {
            $0.top.left.equalToSuperview().offset(10)
            $0.width.height.equalTo(150)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(cardImageView.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(10)
        }

        hpLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel.snp.leading)
        }

        favoriteButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.trailing.equalToSuperview().inset(10)
            $0.width.height.equalTo(30)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        cardImageView.kf.cancelDownloadTask()
        cardImageView.image = nil
        nameLabel.text = nil
        hpLabel.text = nil
        favoriteButton.isSelected = false
    }

    func configure(with card: PokemonCard, isFavorite: Bool) {
        cardInfo = card
        nameLabel.text = card.name
        hpLabel.text = card.hp.map { "HP: \($0)" } ?? "HP: -"
        favoriteButton.isSelected = isFavorite
        animateFavoriteButton(isSelected: isFavorite)

        let options: KingfisherOptionsInfo = [
            .transition(.fade(1)),
            .cacheOriginalImage
        ]

        cardImageView.kf.setImage(with: card.images.small, placeholder: UIImage(named: "placeholder"), options: options, completionHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let value):
                self.cardImageView.image = value.image
            case .failure:
                self.cardImageView.image = UIImage(named: "placeholder")
            }
        })

        favoriteButton.rx.tap
            .map { !isFavorite }
            .subscribe(onNext: { [weak self] isSelected in
                guard let self = self else { return }
                self.animateFavoriteButton(isSelected: isSelected)
                self.favoriteButtonTapped.onNext(isSelected)
            })
            .disposed(by: disposeBag)
    }

    private func animateFavoriteButton(isSelected: Bool) {
        UIView.animate(withDuration: 0.2, animations: {
            if isSelected {
                self.favoriteButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } else {
                self.favoriteButton.transform = CGAffineTransform.identity
            }
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.favoriteButton.transform = isSelected ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        })
    }
}

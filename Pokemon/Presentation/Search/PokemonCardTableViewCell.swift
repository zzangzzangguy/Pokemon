//
//  PokemonCardTableViewCell.swift
//  Pokemon
//
//  Created by 김기현 on 2/24/24.
//

import UIKit
import Kingfisher
import Then
import SnapKit
import RxDataSources

class PokemonCardTableViewCell: UITableViewCell {
    let cardImageView = UIImageView().then {
//        $0.backgroundColor = .red
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    let nameLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
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
        self.contentView.addSubview(cardImageView)
        self.contentView.addSubview(nameLabel)
    }

    private func setupLayout() {
        cardImageView.snp.makeConstraints {
            $0.top.left.equalToSuperview().offset(10)
                $0.width.height.equalTo(150)
            }

               nameLabel.snp.makeConstraints {
                   $0.leading.equalTo(cardImageView.snp.trailing).offset(10) //
                   $0.trailing.equalToSuperview().inset(10)
               }
           }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardImageView.image = nil
        nameLabel.text = nil
    }

    func configure(with card: PokemonCard) {
        nameLabel.text = card.name
        cardImageView.kf.setImage(with: card.imageUrlSmall, placeholder: UIImage(named: "placeholder"), options: [.transition(.fade(1))], completionHandler:  { result in
            switch result {
            case .success(let value):
                print("이미지 로드 성공: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("이미지 로드 실패: \(error.localizedDescription)")
            }
        })
    }
}

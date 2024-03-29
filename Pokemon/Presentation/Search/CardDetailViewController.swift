//
//  CardDetailViewController.swift
//  Pokemon
//
//  Created by 김기현 on 3/18/24.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

class CardDetailViewController: UIViewController {
    
    private let card: PokemonCard
    private let disposeBag = DisposeBag()
    var favoriteStatusChanged = PublishSubject<Bool>()
    
    
    private let cardImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let nameLabel = UILabel().then {
        $0.font = UIFont.boldSystemFont(ofSize: 24)
    }
    
    private let hpLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 18)
        $0.textColor = .red
    }
    
    private let typesLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
    }
    
    private let favoriteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "star"), for: .normal)
        $0.setImage(UIImage(systemName: "star.fill"), for: .selected)
        $0.tintColor = .systemYellow
    }
    private let rarityLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .darkGray
    }
    
    init(card: PokemonCard) {
        self.card = card
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindUI()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        
        view.addSubview(cardImageView)
        view.addSubview(nameLabel)
        view.addSubview(hpLabel)
        view.addSubview(typesLabel)
        view.addSubview(favoriteButton)
        view.addSubview(rarityLabel)
        
        
        cardImageView.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(200)
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(cardImageView.snp.top)
            $0.leading.equalTo(cardImageView.snp.trailing).offset(20)
        }
        
        hpLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(10)
            $0.leading.equalTo(nameLabel.snp.leading)
        }
        
        typesLabel.snp.makeConstraints {
            $0.top.equalTo(hpLabel.snp.bottom).offset(10)
            $0.leading.equalTo(nameLabel.snp.leading)
        }
        
        favoriteButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(40)
        }
        rarityLabel.snp.makeConstraints {
            $0.top.equalTo(hpLabel.snp.bottom).offset(30)
            $0.leading.equalTo(nameLabel.snp.leading)
        }
    }
    
    private func bindUI() {
        nameLabel.text = card.name
        hpLabel.text = "HP: \(card.hp ?? "-")"
        typesLabel.text = "타입: \(card.types?.joined(separator: ", ") ?? "-")"
        rarityLabel.text = "등급: \(card.rarity ?? "-")"
        cardImageView.kf.setImage(with: card.images.large, placeholder: UIImage(named: "placeholder"))
        
        favoriteButton.isSelected = RealmManager.shared.getCard(withId: card.id)?.isFavorite ?? false
        favoriteButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { vc, _ in
                vc.toggleFavorite()
            })
            .disposed(by: disposeBag)
    }
    private func toggleFavorite() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let isFavoriteNow: Bool
            if let realmCard = RealmManager.shared.getCard(withId: self.card.id) {
                // 현재 즐겨찾기 상태를 반전시키고 데이터베이스 업데이트
                isFavoriteNow = !realmCard.isFavorite
                RealmManager.shared.updateFavorite(for: self.card.id, isFavorite: isFavoriteNow)
            } else {
                let newRealmCard = RealmPokemonCard(pokemonCard: self.card)
                newRealmCard.isFavorite = true
                RealmManager.shared.addCard(newRealmCard)
                isFavoriteNow = true
            }
            
            self.favoriteButton.isSelected = isFavoriteNow
            // 상태 변경을 PublishSubject를 통해 알림
            self.favoriteStatusChanged.onNext(isFavoriteNow)
        }
    }
}

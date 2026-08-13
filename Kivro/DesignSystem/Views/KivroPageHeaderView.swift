import UIKit
import SnapKit

enum KivroPageHeaderLayout {
    static let height: CGFloat = 105
    static let horizontalInset: CGFloat = 16
    static let buttonTop: CGFloat = 54
    static let buttonSize: CGFloat = 40
    static let titleLeading: CGFloat = 76
    static let titleTop: CGFloat = 56
}

final class KivroPageHeaderView: UIView {
    var onBack: (() -> Void)?

    private let titleLabel = UILabel()
    private let backButton = KivroBackButton()

    init(title: String) {
        super.init(frame: .zero)
        configureView(title: title)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView(title: "")
    }

    private func configureView(title: String) {
        backgroundColor = .clear

        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = KivroTypography.inter(size: 30, weight: .bold)

        addSubview(backButton)
        addSubview(titleLabel)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(KivroPageHeaderLayout.horizontalInset)
            make.top.equalToSuperview().offset(KivroPageHeaderLayout.buttonTop)
            make.size.equalTo(KivroPageHeaderLayout.buttonSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(KivroPageHeaderLayout.titleLeading)
            make.top.equalToSuperview().offset(KivroPageHeaderLayout.titleTop)
        }
    }

    @objc private func goBack() {
        onBack?()
    }
}

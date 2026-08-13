import UIKit
import SnapKit

final class KivroTextField: UITextField {
    init(localizationKey: String, secure: Bool = false) {
        super.init(frame: .zero)
        placeholder = KivroStrings.value(localizationKey)
        isSecureTextEntry = secure
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        borderStyle = .none
        textColor = .white
        tintColor = .white
        font = KivroTypography.inter(size: 13, weight: .regular)
        attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
        )
        layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        layer.borderWidth = 0
        let border = UIView(frame: .zero)
        border.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        addSubview(border)
        border.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
}

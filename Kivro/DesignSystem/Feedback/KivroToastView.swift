import UIKit
import SnapKit

final class KivroToastView: UIView {
    init(message: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor

        let label = UILabel()
        label.text = message
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = KivroTypography.inter(size: 13, weight: .semibold)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }
}

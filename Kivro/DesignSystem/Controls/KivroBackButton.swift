import UIKit

final class KivroBackButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAppearance()
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.65 : 1
        }
    }

    private func configureAppearance() {
        setImage(
            UIImage(named: "kivro_navigation_back")?.withRenderingMode(.alwaysOriginal),
            for: .normal
        )
        imageView?.contentMode = .scaleAspectFit
        accessibilityLabel = "Back"
    }
}

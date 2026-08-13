import UIKit

final class KivroDialogButton: UIButton {
    enum Style {
        case primary
        case secondary

        var backgroundImageName: String {
            switch self {
            case .primary:
                return "kivro_dialog_button_primary"
            case .secondary:
                return "kivro_dialog_button_secondary"
            }
        }
    }

    init(style: Style) {
        super.init(frame: .zero)
        configureAppearance(style: style)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAppearance(style: .primary)
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.68 : 1
        }
    }

    private func configureAppearance(style: Style) {
        setBackgroundImage(
            UIImage(named: style.backgroundImageName)?.withRenderingMode(.alwaysOriginal),
            for: .normal
        )
        setTitleColor(.black, for: .normal)
        titleLabel?.font = KivroTypography.inter(size: 18, weight: .bold)
    }
}

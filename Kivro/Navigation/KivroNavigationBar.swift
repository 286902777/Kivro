import UIKit

final class KivroNavigationBar: UINavigationBar {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAppearance()
    }

    private func configureAppearance() {
        isTranslucent = true
        prefersLargeTitles = true
        tintColor = .white

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: KivroTypography.inter(size: 20, weight: .bold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: KivroTypography.inter(size: 40, weight: .heavy, italic: true)
        ]
        standardAppearance = appearance
        compactAppearance = appearance
        scrollEdgeAppearance = appearance
    }
}

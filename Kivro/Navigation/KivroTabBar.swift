import UIKit

final class KivroTabBar: UITabBar {
    private let visualContentView = UIView()
    private var itemImageViews: [UIImageView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
        configureVisualItems()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAppearance()
        configureVisualItems()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 74)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 18
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let contentWidth = min(bounds.width, 600)
        visualContentView.frame = CGRect(
            x: (bounds.width - contentWidth) / 2,
            y: 0,
            width: contentWidth,
            height: bounds.height
        )
        visualContentView.layer.cornerRadius = 18
        visualContentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bringSubviewToFront(visualContentView)

        let slotWidth = contentWidth / CGFloat(max(itemImageViews.count, 1))
        for (index, imageView) in itemImageViews.enumerated() {
            imageView.frame = CGRect(
                x: slotWidth * CGFloat(index) + (slotWidth - 38) / 2,
                y: 11,
                width: 38,
                height: 38
            )
        }

        if bounds.width > 600 {
            itemPositioning = .centered
            itemWidth = slotWidth
            itemSpacing = 0
        } else {
            itemPositioning = .fill
        }
    }

    func setSelectedIndex(_ index: Int) {
        for (itemIndex, imageView) in itemImageViews.enumerated() {
            let item = KivroTabItem.allCases[itemIndex]
            let imageName = itemIndex == index ? item.selectedImageName : item.imageName
            imageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
        }
    }

    private func configureAppearance() {
        isTranslucent = false
        backgroundColor = .white
        backgroundImage = UIImage()
        shadowImage = UIImage()
        selectionIndicatorImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
            UIColor.clear.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }.resizableImage(withCapInsets: .zero)
        clipsToBounds = true
        itemPositioning = .fill

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        standardAppearance = appearance
        if #available(iOS 15.0, *) {
            scrollEdgeAppearance = appearance
        }
    }

    private func configureVisualItems() {
        visualContentView.backgroundColor = .white
        visualContentView.clipsToBounds = true
        visualContentView.isUserInteractionEnabled = false
        visualContentView.isAccessibilityElement = false
        addSubview(visualContentView)

        itemImageViews = KivroTabItem.allCases.map { item in
            let imageView = UIImageView(
                image: UIImage(named: item.imageName)?.withRenderingMode(.alwaysOriginal)
            )
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = false
            imageView.isAccessibilityElement = false
            visualContentView.addSubview(imageView)
            return imageView
        }
    }
}

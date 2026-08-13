import UIKit

enum KivroTypography {
    static func inter(
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        italic: Bool = false
    ) -> UIFont {
        var traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight]
        if italic {
            traits[.symbolic] = UIFontDescriptor.SymbolicTraits.traitItalic.rawValue
        }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Inter",
            .traits: traits
        ])
        let font = UIFont(descriptor: descriptor, size: size)
        return font.familyName == "Inter" ? font : .systemFont(ofSize: size, weight: weight)
    }

    static func kavoon(size: CGFloat) -> UIFont {
        UIFont(name: "Kavoon-Regular", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}

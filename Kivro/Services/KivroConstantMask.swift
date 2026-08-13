import Foundation

enum KivroConstantMask {
    @inline(never)
    static func join(_ fragments: String...) -> String {
        fragments.joined()
    }
}

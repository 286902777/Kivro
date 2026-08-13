import Foundation

struct KivroRadarProfile {
    let identifier: String
    let name: String
    let archetype: String
    let avatarAssetName: String
    let radarCopy: String?

    static var all: [KivroRadarProfile] {
        KivroSeedDatabase.shared.radarUsers().map {
            KivroRadarProfile(
                identifier: $0.identifier,
                name: $0.username,
                archetype: $0.category,
                avatarAssetName: $0.avatarAssetName,
                radarCopy: $0.radarCopy
            )
        }
    }
}

import Foundation

struct CoinPackage: Hashable {
    let productIdentifier: String
    let coinAmount: Int
    let displayPriceKey: String

    static let rechargePackages: [CoinPackage] = [
        CoinPackage(productIdentifier: KivroConstantMask.join("lvbsvhxc", "gcrvesor"), coinAmount: 400, displayPriceKey: "recharge.price.400"),
        CoinPackage(productIdentifier: KivroConstantMask.join("dxismgcw", "ewhrtezo"), coinAmount: 2_450, displayPriceKey: "recharge.price.2450"),
        CoinPackage(productIdentifier: KivroConstantMask.join("khtxlcej", "axmqcsra"), coinAmount: 5_150, displayPriceKey: "recharge.price.5150"),
        CoinPackage(productIdentifier: KivroConstantMask.join("yadwwvxs", "pgxwlndb"), coinAmount: 10_800, displayPriceKey: "recharge.price.10800"),
        CoinPackage(productIdentifier: KivroConstantMask.join("qnrcuelb", "tiuflyky"), coinAmount: 29_400, displayPriceKey: "recharge.price.29400"),
        CoinPackage(productIdentifier: KivroConstantMask.join("ymohxnv", "pkqxutvab"), coinAmount: 63_700, displayPriceKey: "recharge.price.63700") // test
//        CoinPackage(productIdentifier: "vjgxapkzmgbfpsmx", coinAmount: 400, displayPriceKey: "recharge.price.400"),
//        CoinPackage(productIdentifier: "asrpigfoqgvgphor", coinAmount: 800, displayPriceKey: "recharge.price.800"),
//        CoinPackage(productIdentifier: "pmihczsmmtgujiip", coinAmount: 2_450, displayPriceKey: "recharge.price.2450"),
//        CoinPackage(productIdentifier: "chvyhppdjcxeowfu", coinAmount: 5_150, displayPriceKey: "recharge.price.5150"),
//        CoinPackage(productIdentifier: "nzkkiuxkxewoblsh", coinAmount: 6_400, displayPriceKey: "recharge.price.6400"),
//        CoinPackage(productIdentifier: "mibeapzeyczvtuql", coinAmount: 10_800, displayPriceKey: "recharge.price.10800"),
//        CoinPackage(productIdentifier: "jduymrwxnapmfjjp", coinAmount: 14_900, displayPriceKey: "recharge.price.14900"),
//        CoinPackage(productIdentifier: "gsodsnwubjebyssz", coinAmount: 29_400, displayPriceKey: "recharge.price.29400"),
//        CoinPackage(productIdentifier: "waizjnusynkqcvow", coinAmount: 39_500, displayPriceKey: "recharge.price.39500"),
//        CoinPackage(productIdentifier: "irdqtzckmjkdeajm", coinAmount: 63_700, displayPriceKey: "recharge.price.63700")
    ]
}

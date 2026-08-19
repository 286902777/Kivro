import UIKit
import SnapKit
import StoreKit

final class RechargeViewController: KivroViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate {
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let packages = CoinPackage.rechargePackages
    private let storeService = KivroStoreKitService.shared
    private let loadingOverlay = KivroLoadingOverlay()
    private let balanceValueLabel = UILabel()
    private var isPurchasing = false
    private var isLoadingProducts = false
    private var selectedPackage: CoinPackage?
    private var purchasingUserIdentifier: String?
    private var productsByIdentifier: [String: Product] = [:]
    private var productLoadingTask: Task<Void, Never>?
    private var purchaseTask: Task<Void, Never>?
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(walletDidChange),
            name: .kivroCoinBalanceDidChange,
            object: nil
        )
        refreshBalance()
        loadProducts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshBalance()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let header = KivroPageHeaderView(title: "Recharge")
        header.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        let balanceCard = UIView()
        balanceCard.backgroundColor = UIColor(red: 73 / 255, green: 33 / 255, blue: 76 / 255, alpha: 1)
        balanceCard.layer.cornerRadius = 23
        view.addSubview(balanceCard)
        balanceCard.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(21)
            make.top.equalToSuperview().offset(131)
            make.height.equalTo(82)
        }

        let coins = UIImageView(image: UIImage(named: "kivro_coin_badge"))
        coins.contentMode = .scaleAspectFit
        view.addSubview(coins)
        coins.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(102)
            make.size.equalTo(118)
        }

        balanceValueLabel.textColor = .white
        balanceValueLabel.font = KivroTypography.inter(size: 30, weight: .bold)
        view.addSubview(balanceValueLabel)
        balanceValueLabel.snp.makeConstraints { make in
            make.centerX.equalTo(balanceCard.snp.trailing).offset(-85)
            make.top.equalToSuperview().offset(143)
        }

        let caption = UILabel()
        caption.text = "Current Balance"
        caption.textColor = .white
        caption.font = KivroTypography.inter(size: 14, weight: .bold)
        view.addSubview(caption)
        caption.snp.makeConstraints { make in
            make.centerX.equalTo(balanceValueLabel)
            make.top.equalToSuperview().offset(181)
        }

        let tiers = UILabel()
        tiers.text = "RECHARGE TIERS"
        tiers.textColor = .white
        tiers.font = KivroTypography.inter(size: 22, weight: .heavy, italic: true)
        view.addSubview(tiers)
        tiers.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(21)
            make.top.equalToSuperview().offset(237)
        }

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = .zero
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RechargePackageCell.self, forCellWithReuseIdentifier: RechargePackageCell.reuseIdentifier)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(284)
            make.bottom.equalToSuperview()
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 104, height: 112.64)
        layout.minimumInteritemSpacing = 11.2
        layout.minimumLineSpacing = 12.36
        layout.sectionInset = .zero
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        packages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RechargePackageCell.reuseIdentifier, for: indexPath)
        let package = packages[indexPath.item]
        (cell as? RechargePackageCell)?.configure(
            with: package,
            displayPrice: productsByIdentifier[package.productIdentifier]?.displayPrice
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isPurchasing,
              !isLoadingProducts,
              packages.indices.contains(indexPath.item),
              KivroAccountAccess.requireAccount(from: self) else { return }
        guard AppStore.canMakePayments else {
            showToast("recharge.purchase.disabled")
            return
        }
        let package = packages[indexPath.item]
        selectedPackage = package
        purchasingUserIdentifier = currentUserIdentifier
        isPurchasing = true
        collectionView.isUserInteractionEnabled = false
        loadingOverlay.show(in: view)
        purchaseTask = Task { [weak self] in
            guard let self else { return }
            let outcome = await storeService.purchase(
                package: package,
                userIdentifier: purchasingUserIdentifier ?? currentUserIdentifier
            )
            finishPurchase()
            handlePurchaseOutcome(outcome)
        }
    }

    private func loadProducts() {
        guard !isLoadingProducts, !isPurchasing else { return }
        isLoadingProducts = true
        collectionView.isUserInteractionEnabled = false
        loadingOverlay.show(in: view)
        productLoadingTask = Task { [weak self] in
            guard let self else { return }
            defer { finishProductLoading() }
            do {
                productsByIdentifier = try await storeService.products(for: packages)
                collectionView.reloadData()
                if productsByIdentifier.isEmpty {
                    showToast("recharge.purchase.unavailable")
                }
            } catch {
                if !Task.isCancelled {
                    showToast("recharge.purchase.unavailable")
                }
            }
        }
    }

    private func handlePurchaseOutcome(_ outcome: KivroStoreKitService.PurchaseOutcome) {
        switch outcome {
        case .credited:
            refreshBalance()
            showToast("recharge.purchase.success")
        case .alreadyCredited:
            refreshBalance()
        case .pending:
            showToast("recharge.purchase.pending")
        case .cancelled:
            break
        case .unavailable:
            showToast("recharge.purchase.unavailable")
        case .unverified:
            showToast("recharge.purchase.unverified")
        case .mismatched:
            showToast("recharge.purchase.mismatch")
        case .creditFailed:
            showToast("recharge.purchase.credit_failed")
        case .failed:
            showToast("recharge.purchase.failed")
        }
    }

    private func finishPurchase() {
        purchaseTask = nil
        selectedPackage = nil
        purchasingUserIdentifier = nil
        loadingOverlay.hide()
        isPurchasing = false
        collectionView.isUserInteractionEnabled = !isLoadingProducts
    }

    private func finishProductLoading() {
        productLoadingTask = nil
        isLoadingProducts = false
        if !isPurchasing {
            loadingOverlay.hide()
            collectionView.isUserInteractionEnabled = true
        }
    }

    private func refreshBalance() {
        balanceValueLabel.text = String(KivroCoinWallet.shared.balance(for: currentUserIdentifier))
    }

    private func showToast(_ key: String) {
        KivroToastPresenter.show(message: KivroStrings.value(key), in: view)
    }

    @objc private func walletDidChange() {
        refreshBalance()
    }
}

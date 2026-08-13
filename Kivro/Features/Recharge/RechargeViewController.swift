import UIKit
import SnapKit
import StoreKit

final class RechargeViewController: KivroViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    SKProductsRequestDelegate,
    SKRequestDelegate,
    SKPaymentTransactionObserver {
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let packages = CoinPackage.rechargePackages
    private let loadingOverlay = KivroLoadingOverlay()
    private let balanceValueLabel = UILabel()
    private let purchaseContextDefaults = UserDefaults.standard
    private var isPurchasing = false
    private var selectedPackage: CoinPackage?
    private var purchasingUserIdentifier: String?
    private var productsRequest: SKProductsRequest?
    private var isObservingPaymentQueue = false
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
        startObservingPaymentQueue()
        refreshBalance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        startObservingPaymentQueue()
        refreshBalance()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isMovingFromParent || navigationController?.isBeingDismissed == true else { return }
        productsRequest?.cancel()
        stopObservingPaymentQueue()
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
        (cell as? RechargePackageCell)?.configure(with: packages[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isPurchasing,
              packages.indices.contains(indexPath.item),
              KivroAccountAccess.requireAccount(from: self) else { return }
        guard SKPaymentQueue.canMakePayments() else {
            showToast("recharge.purchase.disabled")
            return
        }
        let package = packages[indexPath.item]
        selectedPackage = package
        purchasingUserIdentifier = currentUserIdentifier
        purchaseContextDefaults.set(
            currentUserIdentifier,
            forKey: purchaseUserKey(for: package.productIdentifier)
        )
        isPurchasing = true
        collectionView.isUserInteractionEnabled = false
        loadingOverlay.show(in: view)
        requestProduct(for: package)
    }

    private func requestProduct(for package: CoinPackage) {
        let request = SKProductsRequest(productIdentifiers: [package.productIdentifier])
        productsRequest = request
        request.delegate = self
        request.start()
    }

    private func startObservingPaymentQueue() {
        guard !isObservingPaymentQueue else { return }
        SKPaymentQueue.default().add(self)
        isObservingPaymentQueue = true
    }

    private func stopObservingPaymentQueue() {
        guard isObservingPaymentQueue else { return }
        SKPaymentQueue.default().remove(self)
        isObservingPaymentQueue = false
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productsRequest = nil
        guard isPurchasing,
              let package = selectedPackage,
              let product = response.products.first(where: { $0.productIdentifier == package.productIdentifier }) else {
            if let package = selectedPackage { clearPurchaseUser(for: package.productIdentifier) }
            showToast("recharge.purchase.unavailable")
            finishPurchase()
            return
        }
        SKPaymentQueue.default().add(SKPayment(product: product))
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request === productsRequest else { return }
        productsRequest = nil
        if let package = selectedPackage { clearPurchaseUser(for: package.productIdentifier) }
        showToast("recharge.purchase.unavailable")
        finishPurchase()
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let productIdentifier = transaction.payment.productIdentifier
            guard let package = packages.first(where: { $0.productIdentifier == productIdentifier }),
                  let userIdentifier = purchaseUserIdentifier(for: productIdentifier) else { continue }

            switch transaction.transactionState {
            case .purchased:
                complete(transaction, package: package, userIdentifier: userIdentifier, queue: queue)
            case .failed:
                let wasCancelled = (transaction.error as? SKError)?.code == .paymentCancelled
                queue.finishTransaction(transaction)
                clearPurchaseUser(for: productIdentifier)
                if !wasCancelled { showToast("recharge.purchase.failed") }
                finishPurchase()
            case .deferred:
                showToast("recharge.purchase.pending")
                finishPurchase()
            case .restored:
                queue.finishTransaction(transaction)
                clearPurchaseUser(for: productIdentifier)
                finishPurchase()
            case .purchasing:
                break
            @unknown default:
                queue.finishTransaction(transaction)
                clearPurchaseUser(for: productIdentifier)
                showToast("recharge.purchase.failed")
                finishPurchase()
            }
        }
    }

    private func complete(
        _ transaction: SKPaymentTransaction,
        package: CoinPackage,
        userIdentifier: String,
        queue: SKPaymentQueue
    ) {
        guard transaction.payment.productIdentifier == package.productIdentifier,
              let transactionIdentifier = transaction.transactionIdentifier,
              hasAppStoreReceipt else {
            showToast("recharge.purchase.unverified")
            finishPurchase()
            return
        }

        let creditResult = KivroCoinWallet.shared.creditPurchase(
            package.coinAmount,
            for: userIdentifier,
            transactionIdentifier: transactionIdentifier
        )
        switch creditResult {
        case .credited:
            queue.finishTransaction(transaction)
            clearPurchaseUser(for: package.productIdentifier)
            refreshBalance()
            showToast("recharge.purchase.success")
            finishPurchase()
        case .alreadyCredited:
            queue.finishTransaction(transaction)
            clearPurchaseUser(for: package.productIdentifier)
            refreshBalance()
            finishPurchase()
        case .failed:
            showToast("recharge.purchase.credit_failed")
            finishPurchase()
        }
    }

    private var hasAppStoreReceipt: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else { return false }
        return !receiptData.isEmpty
    }

    private func purchaseUserIdentifier(for productIdentifier: String) -> String? {
        if selectedPackage?.productIdentifier == productIdentifier,
           let purchasingUserIdentifier {
            return purchasingUserIdentifier
        }
        return purchaseContextDefaults.string(forKey: purchaseUserKey(for: productIdentifier))
    }

    private func clearPurchaseUser(for productIdentifier: String) {
        purchaseContextDefaults.removeObject(forKey: purchaseUserKey(for: productIdentifier))
    }

    private func purchaseUserKey(for productIdentifier: String) -> String {
        KivroConstantMask.join("kivro.purchase.", "user.", productIdentifier)
    }

    private func finishPurchase() {
        productsRequest?.cancel()
        productsRequest = nil
        selectedPackage = nil
        purchasingUserIdentifier = nil
        if isPurchasing {
            loadingOverlay.hide()
            isPurchasing = false
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

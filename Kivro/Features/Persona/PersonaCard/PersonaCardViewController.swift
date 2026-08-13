import UIKit
import SnapKit

final class PersonaCardViewController: KivroViewController {
    private static let archetypeNames = ["Cyber", "Mecha", "Anime", "Gothic", "Fantasy", "Period"]
    private let scores: [Int]

    init(scores: [Int] = [87, 72, 61, 44, 35, 22]) {
        let normalizedScores = Array(scores.prefix(Self.archetypeNames.count)).map {
            min(100, max(0, $0))
        }
        self.scores = normalizedScores + Array(
            repeating: 0,
            count: max(0, Self.archetypeNames.count - normalizedScores.count)
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
    }

    private func configureLayout() {
        configureBackground()
        configureCard()
        configureHeader()
        configureHomeIndicator()
    }

    private func configureBackground() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private func configureCard() {
        let primaryIndex = scores.indices.max { scores[$0] < scores[$1] } ?? 0
        let primaryArchetype = Self.archetypeNames[primaryIndex]
        let primaryScore = scores[primaryIndex]
        let panel = UIView()
        panel.backgroundColor = UIColor(red: 47 / 255, green: 42 / 255, blue: 54 / 255, alpha: 1)
        panel.layer.cornerRadius = 26
        view.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(13)
            make.top.equalToSuperview().offset(140)
            make.height.equalTo(729)
        }

        let blueHeader = UIView()
        blueHeader.backgroundColor = UIColor(red: 67 / 255, green: 126 / 255, blue: 202 / 255, alpha: 1)
        blueHeader.layer.cornerRadius = 26
        blueHeader.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.addSubview(blueHeader)
        blueHeader.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(155)
        }

        let badgeAssetName = "kivro_persona_\(primaryArchetype.lowercased())_badge"
        let badge = UIImageView(image: UIImage(named: badgeAssetName))
        badge.contentMode = .scaleAspectFit
        view.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.centerX.equalTo(panel)
            make.top.equalToSuperview().offset(104)
            make.size.equalTo(120)
        }

        addCenteredLabel("\(primaryArchetype) Sentry", to: panel, top: 87, size: 22, weight: .bold)
        addCenteredLabel(
            "P E R S O N A   G E N E   C A R D",
            to: panel,
            top: 122,
            size: 11,
            weight: .medium,
            alpha: 0.65
        )

        let metrics = UIStackView(arrangedSubviews: [
            makeMetric(value: "\(primaryScore)%", caption: "Fit Score"),
            makeMetric(value: "T2", caption: "Rarity"),
            makeMetric(value: "3", caption: "Compat")
        ])
        metrics.axis = .horizontal
        metrics.alignment = .fill
        metrics.distribution = .fillEqually
        metrics.spacing = 10
        panel.addSubview(metrics)
        metrics.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.top.equalToSuperview().offset(179)
            make.height.equalTo(100)
        }

        let affinityTitle = UILabel()
        affinityTitle.text = "Style affinity breakdown"
        affinityTitle.textColor = .white
        affinityTitle.font = KivroTypography.inter(size: 13, weight: .bold)
        panel.addSubview(affinityTitle)
        affinityTitle.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(25)
            make.top.equalToSuperview().offset(304)
        }

        let items = zip(Self.archetypeNames, scores).map { ($0, $1) }
        let colors: [UIColor] = [.systemBlue, .systemYellow, .systemPurple, .systemPink, .systemTeal, .systemCyan]
        for (index, item) in items.enumerated() {
            let rowY = CGFloat(331 + index * 40)
            let row = UILabel()
            row.text = item.0 + "  " + String(item.1) + "%"
            row.textColor = .white
            row.font = KivroTypography.inter(size: 11, weight: .regular)
            panel.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(25)
                make.top.equalToSuperview().offset(rowY)
            }
            let line = UIView()
            line.backgroundColor = UIColor.white.withAlphaComponent(0.35)
            panel.addSubview(line)
            line.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(25)
                make.top.equalToSuperview().offset(rowY + 24)
                make.height.equalTo(2)
            }
            let progress = UIView()
            progress.backgroundColor = colors[index]
            panel.addSubview(progress)
            progress.snp.makeConstraints { make in
                make.leading.equalTo(line)
                make.top.equalToSuperview().offset(rowY + 24)
                make.width.equalTo(line).multipliedBy(CGFloat(item.1) / 100)
                make.height.equalTo(2)
            }
        }
        let body = UILabel()
        body.text = makePersonaSummary()
        body.textColor = .white
        body.numberOfLines = 0
        body.font = KivroTypography.inter(size: 11, weight: .bold)
        panel.addSubview(body)
        body.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(23)
            make.top.equalToSuperview().offset(584)
        }
    }

    private func makePersonaSummary() -> String {
        let rankedIndices = scores.indices.sorted { scores[$0] > scores[$1] }
        guard let primaryIndex = rankedIndices.first else {
            return "An original character concept is waiting for its first style affinity scan."
        }

        let primaryName = Self.archetypeNames[primaryIndex]
        let primaryScore = scores[primaryIndex]
        let secondaryIndex = rankedIndices.dropFirst().first ?? primaryIndex
        let accentIndex = rankedIndices.dropFirst(2).first ?? secondaryIndex
        let secondaryName = Self.archetypeNames[secondaryIndex]
        let accentName = Self.archetypeNames[accentIndex]
        let secondaryScore = scores[secondaryIndex]
        let accentScore = scores[accentIndex]
        let intensity: String
        switch primaryScore {
        case 90...:
            intensity = "legendary"
        case 80..<90:
            intensity = "elite"
        case 65..<80:
            intensity = "strong"
        default:
            intensity = "emerging"
        }

        return "An \(intensity) \(primaryName)-inspired original character concept with \(primaryScore)% affinity. \(secondaryName)-inspired structure at \(secondaryScore)% guides the costume silhouette, while \(accentScore)% \(accentName)-inspired detail adds a distinctive visual accent."
    }

    private func configureHeader() {
        let header = KivroPageHeaderView(title: "Persona Card")
        header.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }
    }

    private func configureHomeIndicator() {
        let indicator = UIView()
        indicator.backgroundColor = .black
        indicator.layer.cornerRadius = 2.5
        view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }
    }

    private func makeMetric(value: String, caption: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 57 / 255, green: 51 / 255, blue: 64 / 255, alpha: 1)
        card.layer.cornerRadius = 18
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textColor = .white
        valueLabel.font = KivroTypography.inter(size: 27, weight: .bold)
        card.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
        }
        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.textColor = .white
        captionLabel.font = KivroTypography.inter(size: 11, weight: .bold)
        card.addSubview(captionLabel)
        captionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(62)
        }
        return card
    }

    private func addCenteredLabel(
        _ text: String,
        to container: UIView,
        top: CGFloat,
        size: CGFloat,
        weight: UIFont.Weight,
        alpha: CGFloat = 1
    ) {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.white.withAlphaComponent(alpha)
        label.font = KivroTypography.inter(size: size, weight: weight)
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
            make.top.equalToSuperview().offset(top)
        }
    }
}

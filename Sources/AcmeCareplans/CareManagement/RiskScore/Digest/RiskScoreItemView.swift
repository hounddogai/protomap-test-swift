import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score item.
    final class RiskScoreItemView {
        var code: String
        var label: String
        var title: String
        var region: String
        var externalRef: String
        var reviewer: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, label: String, title: String, region: String, externalRef: String, reviewer: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.region = region
            self.externalRef = externalRef
            self.reviewer = reviewer
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreItemView(_ item: RiskScoreItem) -> RiskScoreItemView {
        return RiskScoreItemView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            title: Kit.Text.truncate(item.title, limit: 120),
            region: Kit.Text.truncate(item.region, limit: 120),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            reviewer: item.reviewer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreItemViews(_ items: [RiskScoreItem]) -> [RiskScoreItemView] {
        var views: [RiskScoreItemView] = []
        for item in items {
            views.append(toRiskScoreItemView(item))
        }
        return views
    }

    static func sumRiskScoreItemView(_ view: RiskScoreItemView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}

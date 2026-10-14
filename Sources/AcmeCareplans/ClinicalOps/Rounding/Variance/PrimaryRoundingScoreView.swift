import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary rounding score.
    final class PrimaryRoundingScoreView {
        var code: String
        var label: String
        var locale: String
        var checksumText: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, locale: String, checksumText: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.locale = locale
            self.checksumText = checksumText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRoundingScoreView(_ item: PrimaryRoundingScore) -> PrimaryRoundingScoreView {
        return PrimaryRoundingScoreView(
            code: item.code,
            label: item.label,
            locale: item.locale,
            checksumText: item.checksum,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRoundingScoreViews(_ items: [PrimaryRoundingScore]) -> [PrimaryRoundingScoreView] {
        var views: [PrimaryRoundingScoreView] = []
        for item in items {
            views.append(toPrimaryRoundingScoreView(item))
        }
        return views
    }

    static func sumPrimaryRoundingScoreView(_ view: PrimaryRoundingScoreView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}

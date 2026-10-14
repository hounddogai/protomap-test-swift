import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional inventory rollup.
    final class RegionalInventoryRollupView {
        var code: String
        var label: String
        var sequence: String
        var phone: String
        var source: String
        var scoreText: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, label: String, sequence: String, phone: String, source: String, scoreText: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.phone = phone
            self.source = source
            self.scoreText = scoreText
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalInventoryRollupView(_ item: RegionalInventoryRollup) -> RegionalInventoryRollupView {
        return RegionalInventoryRollupView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            sequence: String(item.sequence),
            phone: item.phone,
            source: item.source,
            scoreText: String(format: "%.2f", item.score),
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalInventoryRollupViews(_ items: [RegionalInventoryRollup]) -> [RegionalInventoryRollupView] {
        var views: [RegionalInventoryRollupView] = []
        for item in items {
            views.append(toRegionalInventoryRollupView(item))
        }
        return views
    }

    static func sumRegionalInventoryRollupView(_ view: RegionalInventoryRollupView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedSequence) + parsedScore
    }
}

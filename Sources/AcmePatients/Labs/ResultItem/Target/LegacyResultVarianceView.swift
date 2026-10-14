import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy result variance.
    final class LegacyResultVarianceView {
        var codeText: String
        var title: String
        var category: String
        var expiresAtText: String
        var threshold: String
        var statusLabel: String

        init(codeText: String, title: String, category: String, expiresAtText: String, threshold: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.category = category
            self.expiresAtText = expiresAtText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyResultVarianceView(_ item: LegacyResultVariance) -> LegacyResultVarianceView {
        return LegacyResultVarianceView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            category: item.category,
            expiresAtText: String(item.expiresAt),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyResultVarianceViews(_ items: [LegacyResultVariance]) -> [LegacyResultVarianceView] {
        var views: [LegacyResultVarianceView] = []
        for item in items {
            views.append(toLegacyResultVarianceView(item))
        }
        return views
    }

    static func sumLegacyResultVarianceView(_ view: LegacyResultVarianceView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedExpiresAt) + parsedThreshold
    }
}

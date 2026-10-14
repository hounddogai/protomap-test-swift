import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score digest.
    final class RiskScoreDigestView {
        var code: String
        var label: String
        var threshold: String
        var locale: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, locale: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.locale = locale
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreDigestView(_ item: RiskScoreDigest) -> RiskScoreDigestView {
        return RiskScoreDigestView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            locale: item.locale,
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreDigestViews(_ items: [RiskScoreDigest]) -> [RiskScoreDigestView] {
        var views: [RiskScoreDigestView] = []
        for item in items {
            views.append(toRiskScoreDigestView(item))
        }
        return views
    }

    static func sumRiskScoreDigestView(_ view: RiskScoreDigestView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedThreshold + Double(parsedStartsAt)
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal closure rule.
    final class SeasonalClosureRuleView {
        var code: String
        var labelText: String
        var threshold: String
        var discountText: String
        var weight: String
        var marginText: String
        var pinned: String
        var clinicianID: String
        var ratio: String
        var statusLabel: String

        init(code: String, labelText: String, threshold: String, discountText: String, weight: String, marginText: String, pinned: String, clinicianID: String, ratio: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.threshold = threshold
            self.discountText = discountText
            self.weight = weight
            self.marginText = marginText
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalClosureRuleView(_ item: SeasonalClosureRule) -> SeasonalClosureRuleView {
        return SeasonalClosureRuleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            threshold: String(format: "%.2f", item.threshold),
            discountText: String(format: "%.2f", item.discount),
            weight: String(format: "%.2f", item.weight),
            marginText: String(format: "%.2f", item.margin),
            pinned: "\(item.pinned)",
            clinicianID: item.clinicianID,
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalClosureRuleViews(_ items: [SeasonalClosureRule]) -> [SeasonalClosureRuleView] {
        var views: [SeasonalClosureRuleView] = []
        for item in items {
            views.append(toSeasonalClosureRuleView(item))
        }
        return views
    }

    static func sumSeasonalClosureRuleView(_ view: SeasonalClosureRuleView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedThreshold + parsedDiscount + parsedWeight
    }
}

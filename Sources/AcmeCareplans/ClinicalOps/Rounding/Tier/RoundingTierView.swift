import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding tier.
    final class RoundingTierView {
        var code: String
        var name: String
        var timezone: String
        var thresholdText: String
        var phoneText: String
        var source: String
        var ward: String
        var country: String
        var patientRefText: String
        var limit: String
        var statusLabel: String

        init(code: String, name: String, timezone: String, thresholdText: String, phoneText: String, source: String, ward: String, country: String, patientRefText: String, limit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.thresholdText = thresholdText
            self.phoneText = phoneText
            self.source = source
            self.ward = ward
            self.country = country
            self.patientRefText = patientRefText
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingTierView(_ item: RoundingTier) -> RoundingTierView {
        return RoundingTierView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            thresholdText: String(format: "%.2f", item.threshold),
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            source: item.source,
            ward: item.ward,
            country: item.country,
            patientRefText: item.patientRef,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingTierViews(_ items: [RoundingTier]) -> [RoundingTierView] {
        var views: [RoundingTierView] = []
        for item in items {
            views.append(toRoundingTierView(item))
        }
        return views
    }

    static func sumRoundingTierView(_ view: RoundingTierView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedThreshold + Double(parsedLimit)
    }
}

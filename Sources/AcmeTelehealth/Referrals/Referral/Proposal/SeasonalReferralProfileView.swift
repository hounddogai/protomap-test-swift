import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal referral profile.
    final class SeasonalReferralProfileView {
        var code: String
        var label: String
        var ward: String
        var ceiling: String
        var graceDays: String
        var allergy: String
        var durationMinutes: String
        var weight: String
        var statusLabel: String

        init(code: String, label: String, ward: String, ceiling: String, graceDays: String, allergy: String, durationMinutes: String, weight: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ward = ward
            self.ceiling = ceiling
            self.graceDays = graceDays
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReferralProfileView(_ item: SeasonalReferralProfile) -> SeasonalReferralProfileView {
        return SeasonalReferralProfileView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            ward: item.ward,
            ceiling: String(format: "%.2f", item.ceiling),
            graceDays: String(item.graceDays),
            allergy: item.allergy,
            durationMinutes: String(item.durationMinutes),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReferralProfileViews(_ items: [SeasonalReferralProfile]) -> [SeasonalReferralProfileView] {
        var views: [SeasonalReferralProfileView] = []
        for item in items {
            views.append(toSeasonalReferralProfileView(item))
        }
        return views
    }

    static func sumSeasonalReferralProfileView(_ view: SeasonalReferralProfileView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCeiling + Double(parsedGraceDays) + Double(parsedDurationMinutes)
    }
}

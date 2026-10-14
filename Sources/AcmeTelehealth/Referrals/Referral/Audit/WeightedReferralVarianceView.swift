import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted referral variance.
    final class WeightedReferralVarianceView {
        var codeText: String
        var name: String
        var durationMinutesText: String
        var copay: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, name: String, durationMinutesText: String, copay: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.durationMinutesText = durationMinutesText
            self.copay = copay
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReferralVarianceView(_ item: WeightedReferralVariance) -> WeightedReferralVarianceView {
        return WeightedReferralVarianceView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            durationMinutesText: String(item.durationMinutes),
            copay: String(format: "%.2f", item.copay),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReferralVarianceViews(_ items: [WeightedReferralVariance]) -> [WeightedReferralVarianceView] {
        var views: [WeightedReferralVarianceView] = []
        for item in items {
            views.append(toWeightedReferralVarianceView(item))
        }
        return views
    }

    static func sumWeightedReferralVarianceView(_ view: WeightedReferralVarianceView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedDurationMinutes) + parsedCopay + parsedMinimum
    }
}

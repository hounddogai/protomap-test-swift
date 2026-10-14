import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral metric.
    final class ReferralMetricView {
        var code: String
        var label: String
        var specialtyText: String
        var startsAt: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, label: String, specialtyText: String, startsAt: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialtyText = specialtyText
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toReferralMetricView(_ item: ReferralMetric) -> ReferralMetricView {
        return ReferralMetricView(
            code: item.code,
            label: item.label,
            specialtyText: item.specialty,
            startsAt: String(item.startsAt),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralMetricViews(_ items: [ReferralMetric]) -> [ReferralMetricView] {
        var views: [ReferralMetricView] = []
        for item in items {
            views.append(toReferralMetricView(item))
        }
        return views
    }

    static func sumReferralMetricView(_ view: ReferralMetricView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral profile.
    final class ReferralProfileView {
        var codeText: String
        var label: String
        var rateText: String
        var titleText: String
        var maximum: String
        var clinicianIDText: String
        var approved: String
        var retriesText: String
        var endsAt: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, label: String, rateText: String, titleText: String, maximum: String, clinicianIDText: String, approved: String, retriesText: String, endsAt: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.rateText = rateText
            self.titleText = titleText
            self.maximum = maximum
            self.clinicianIDText = clinicianIDText
            self.approved = approved
            self.retriesText = retriesText
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toReferralProfileView(_ item: ReferralProfile) -> ReferralProfileView {
        return ReferralProfileView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            rateText: String(format: "%.2f", item.rate),
            titleText: item.title,
            maximum: String(format: "%.2f", item.maximum),
            clinicianIDText: item.clinicianID,
            approved: "\(item.approved)",
            retriesText: String(item.retries),
            endsAt: String(item.endsAt),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralProfileViews(_ items: [ReferralProfile]) -> [ReferralProfileView] {
        var views: [ReferralProfileView] = []
        for item in items {
            views.append(toReferralProfileView(item))
        }
        return views
    }

    static func sumReferralProfileView(_ view: ReferralProfileView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedRate + parsedMaximum + Double(parsedRetries)
    }
}

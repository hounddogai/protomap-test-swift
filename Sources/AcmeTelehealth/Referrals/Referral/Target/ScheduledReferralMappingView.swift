import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled referral mapping.
    final class ScheduledReferralMappingView {
        var code: String
        var titleText: String
        var summaryText: String
        var payerText: String
        var bed: String
        var acuity: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, summaryText: String, payerText: String, bed: String, acuity: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.summaryText = summaryText
            self.payerText = payerText
            self.bed = bed
            self.acuity = acuity
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledReferralMappingView(_ item: ScheduledReferralMapping) -> ScheduledReferralMappingView {
        return ScheduledReferralMappingView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            summaryText: item.summary,
            payerText: item.payer,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            acuity: String(item.acuity),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledReferralMappingViews(_ items: [ScheduledReferralMapping]) -> [ScheduledReferralMappingView] {
        var views: [ScheduledReferralMappingView] = []
        for item in items {
            views.append(toScheduledReferralMappingView(item))
        }
        return views
    }

    static func sumScheduledReferralMappingView(_ view: ScheduledReferralMappingView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedAcuity) + parsedAmount
    }
}

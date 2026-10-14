import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual referral mapping.
    final class ManualReferralMappingView {
        var code: String
        var labelText: String
        var descriptionText: String
        var amountText: String
        var windowDaysText: String
        var ceiling: String
        var scoreText: String
        var currency: String
        var version: String
        var contactEmailText: String
        var statusLabel: String

        init(code: String, labelText: String, descriptionText: String, amountText: String, windowDaysText: String, ceiling: String, scoreText: String, currency: String, version: String, contactEmailText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.descriptionText = descriptionText
            self.amountText = amountText
            self.windowDaysText = windowDaysText
            self.ceiling = ceiling
            self.scoreText = scoreText
            self.currency = currency
            self.version = version
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toManualReferralMappingView(_ item: ManualReferralMapping) -> ManualReferralMappingView {
        return ManualReferralMappingView(
            code: item.code,
            labelText: item.label,
            descriptionText: Kit.Text.truncate(item.description, limit: 80),
            amountText: String(format: "%.2f", item.amount),
            windowDaysText: String(item.windowDays),
            ceiling: String(format: "%.2f", item.ceiling),
            scoreText: String(format: "%.2f", item.score),
            currency: item.currency,
            version: String(item.version),
            contactEmailText: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualReferralMappingViews(_ items: [ManualReferralMapping]) -> [ManualReferralMappingView] {
        var views: [ManualReferralMappingView] = []
        for item in items {
            views.append(toManualReferralMappingView(item))
        }
        return views
    }

    static func sumManualReferralMappingView(_ view: ManualReferralMappingView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedAmount + Double(parsedWindowDays) + parsedCeiling
    }
}

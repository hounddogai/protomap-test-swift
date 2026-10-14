import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal care gap plan.
    final class SeasonalCareGapPlanView {
        var code: String
        var titleText: String
        var phone: String
        var amount: String
        var contactEmail: String
        var pinned: String
        var statusLabel: String

        init(code: String, titleText: String, phone: String, amount: String, contactEmail: String, pinned: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.phone = phone
            self.amount = amount
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareGapPlanView(_ item: SeasonalCareGapPlan) -> SeasonalCareGapPlanView {
        return SeasonalCareGapPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            amount: String(format: "%.2f", item.amount),
            contactEmail: item.contactEmail,
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareGapPlanViews(_ items: [SeasonalCareGapPlan]) -> [SeasonalCareGapPlanView] {
        var views: [SeasonalCareGapPlanView] = []
        for item in items {
            views.append(toSeasonalCareGapPlanView(item))
        }
        return views
    }

    static func sumSeasonalCareGapPlanView(_ view: SeasonalCareGapPlanView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}

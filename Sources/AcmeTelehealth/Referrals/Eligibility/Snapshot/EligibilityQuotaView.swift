import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility quota.
    final class EligibilityQuotaView {
        var code: String
        var label: String
        var quantity: String
        var procedureCode: String
        var budgetText: String
        var startsAt: String
        var version: String
        var statusLabel: String

        init(code: String, label: String, quantity: String, procedureCode: String, budgetText: String, startsAt: String, version: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.procedureCode = procedureCode
            self.budgetText = budgetText
            self.startsAt = startsAt
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityQuotaView(_ item: EligibilityQuota) -> EligibilityQuotaView {
        return EligibilityQuotaView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            quantity: String(item.quantity),
            procedureCode: item.procedureCode,
            budgetText: String(format: "%.2f", item.budget),
            startsAt: String(item.startsAt),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityQuotaViews(_ items: [EligibilityQuota]) -> [EligibilityQuotaView] {
        var views: [EligibilityQuotaView] = []
        for item in items {
            views.append(toEligibilityQuotaView(item))
        }
        return views
    }

    static func sumEligibilityQuotaView(_ view: EligibilityQuotaView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedQuantity) + parsedBudget + Double(parsedStartsAt)
    }
}

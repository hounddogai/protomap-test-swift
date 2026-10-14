import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending eligibility variance.
    final class PendingEligibilityVarianceView {
        var code: String
        var title: String
        var channel: String
        var locale: String
        var priority: String
        var payer: String
        var amount: String
        var refills: String
        var attemptsText: String
        var updatedAt: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, channel: String, locale: String, priority: String, payer: String, amount: String, refills: String, attemptsText: String, updatedAt: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.channel = channel
            self.locale = locale
            self.priority = priority
            self.payer = payer
            self.amount = amount
            self.refills = refills
            self.attemptsText = attemptsText
            self.updatedAt = updatedAt
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toPendingEligibilityVarianceView(_ item: PendingEligibilityVariance) -> PendingEligibilityVarianceView {
        return PendingEligibilityVarianceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            channel: item.channel,
            locale: item.locale,
            priority: String(item.priority),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            amount: String(format: "%.2f", item.amount),
            refills: String(item.refills),
            attemptsText: String(item.attempts),
            updatedAt: String(item.updatedAt),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingEligibilityVarianceViews(_ items: [PendingEligibilityVariance]) -> [PendingEligibilityVarianceView] {
        var views: [PendingEligibilityVarianceView] = []
        for item in items {
            views.append(toPendingEligibilityVarianceView(item))
        }
        return views
    }

    static func sumPendingEligibilityVarianceView(_ view: PendingEligibilityVarianceView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedPriority) + parsedAmount + Double(parsedRefills)
    }
}

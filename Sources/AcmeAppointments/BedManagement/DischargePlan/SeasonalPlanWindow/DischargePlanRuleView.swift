import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan rule.
    final class DischargePlanRuleView {
        var code: String
        var title: String
        var quantity: String
        var attempts: String
        var dosageMg: String
        var notes: String
        var minimum: String
        var limit: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, attempts: String, dosageMg: String, notes: String, minimum: String, limit: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.notes = notes
            self.minimum = minimum
            self.limit = limit
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanRuleView(_ item: DischargePlanRule) -> DischargePlanRuleView {
        return DischargePlanRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            quantity: String(item.quantity),
            attempts: String(item.attempts),
            dosageMg: String(format: "%.2f", item.dosageMg),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            limit: String(item.limit),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanRuleViews(_ items: [DischargePlanRule]) -> [DischargePlanRuleView] {
        var views: [DischargePlanRuleView] = []
        for item in items {
            views.append(toDischargePlanRuleView(item))
        }
        return views
    }

    static func sumDischargePlanRuleView(_ view: DischargePlanRuleView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedQuantity) + Double(parsedAttempts) + parsedDosageMg
    }
}

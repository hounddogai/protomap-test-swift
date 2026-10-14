import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert cycle.
    final class AlertCycleView {
        var code: String
        var labelText: String
        var category: String
        var ownerID: String
        var phone: String
        var currency: String
        var amountText: String
        var statusLabel: String

        init(code: String, labelText: String, category: String, ownerID: String, phone: String, currency: String, amountText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.category = category
            self.ownerID = ownerID
            self.phone = phone
            self.currency = currency
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toAlertCycleView(_ item: AlertCycle) -> AlertCycleView {
        return AlertCycleView(
            code: item.code,
            labelText: item.label,
            category: item.category,
            ownerID: item.ownerID,
            phone: Kit.Text.truncate(item.phone, limit: 120),
            currency: item.currency,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertCycleViews(_ items: [AlertCycle]) -> [AlertCycleView] {
        var views: [AlertCycleView] = []
        for item in items {
            views.append(toAlertCycleView(item))
        }
        return views
    }

    static func sumAlertCycleView(_ view: AlertCycleView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}

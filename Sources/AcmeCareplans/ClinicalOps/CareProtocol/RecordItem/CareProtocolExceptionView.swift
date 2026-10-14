import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol exception.
    final class CareProtocolExceptionView {
        var code: String
        var title: String
        var description: String
        var active: String
        var amount: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, description: String, active: String, amount: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.active = active
            self.amount = amount
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolExceptionView(_ item: CareProtocolException) -> CareProtocolExceptionView {
        return CareProtocolExceptionView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            description: item.description,
            active: "\(item.active)",
            amount: String(format: "%.2f", item.amount),
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolExceptionViews(_ items: [CareProtocolException]) -> [CareProtocolExceptionView] {
        var views: [CareProtocolExceptionView] = []
        for item in items {
            views.append(toCareProtocolExceptionView(item))
        }
        return views
    }

    static func sumCareProtocolExceptionView(_ view: CareProtocolExceptionView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}

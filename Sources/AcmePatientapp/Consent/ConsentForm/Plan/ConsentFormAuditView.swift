import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form audit.
    final class ConsentFormAuditView {
        var code: String
        var nameText: String
        var quantity: String
        var cost: String
        var capacity: String
        var statusLabel: String

        init(code: String, nameText: String, quantity: String, cost: String, capacity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.quantity = quantity
            self.cost = cost
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormAuditView(_ item: ConsentFormAudit) -> ConsentFormAuditView {
        return ConsentFormAuditView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            quantity: String(item.quantity),
            cost: String(format: "%.2f", item.cost),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormAuditViews(_ items: [ConsentFormAudit]) -> [ConsentFormAuditView] {
        var views: [ConsentFormAuditView] = []
        for item in items {
            views.append(toConsentFormAuditView(item))
        }
        return views
    }

    static func sumConsentFormAuditView(_ view: ConsentFormAuditView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedQuantity) + parsedCost + Double(parsedCapacity)
    }
}

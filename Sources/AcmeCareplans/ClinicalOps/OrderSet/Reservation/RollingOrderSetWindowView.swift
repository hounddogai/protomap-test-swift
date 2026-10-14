import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling order set window.
    final class RollingOrderSetWindowView {
        var code: String
        var name: String
        var attempts: String
        var quantity: String
        var currency: String
        var sequence: String
        var margin: String
        var category: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, quantity: String, currency: String, sequence: String, margin: String, category: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.quantity = quantity
            self.currency = currency
            self.sequence = sequence
            self.margin = margin
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toRollingOrderSetWindowView(_ item: RollingOrderSetWindow) -> RollingOrderSetWindowView {
        return RollingOrderSetWindowView(
            code: item.code,
            name: item.name,
            attempts: String(item.attempts),
            quantity: String(item.quantity),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            sequence: String(item.sequence),
            margin: String(format: "%.2f", item.margin),
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingOrderSetWindowViews(_ items: [RollingOrderSetWindow]) -> [RollingOrderSetWindowView] {
        var views: [RollingOrderSetWindowView] = []
        for item in items {
            views.append(toRollingOrderSetWindowView(item))
        }
        return views
    }

    static func sumRollingOrderSetWindowView(_ view: RollingOrderSetWindowView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedAttempts) + Double(parsedQuantity) + Double(parsedSequence)
    }
}

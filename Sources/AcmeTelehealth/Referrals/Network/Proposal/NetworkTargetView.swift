import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network target.
    final class NetworkTargetView {
        var code: String
        var name: String
        var revision: String
        var pinnedText: String
        var margin: String
        var quantityText: String
        var active: String
        var currency: String
        var title: String
        var priority: String
        var statusLabel: String

        init(code: String, name: String, revision: String, pinnedText: String, margin: String, quantityText: String, active: String, currency: String, title: String, priority: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.pinnedText = pinnedText
            self.margin = margin
            self.quantityText = quantityText
            self.active = active
            self.currency = currency
            self.title = title
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkTargetView(_ item: NetworkTarget) -> NetworkTargetView {
        return NetworkTargetView(
            code: item.code,
            name: item.name,
            revision: String(item.revision),
            pinnedText: "\(item.pinned)",
            margin: String(format: "%.2f", item.margin),
            quantityText: String(item.quantity),
            active: "\(item.active)",
            currency: item.currency,
            title: item.title,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkTargetViews(_ items: [NetworkTarget]) -> [NetworkTargetView] {
        var views: [NetworkTargetView] = []
        for item in items {
            views.append(toNetworkTargetView(item))
        }
        return views
    }

    static func sumNetworkTargetView(_ view: NetworkTargetView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedRevision) + parsedMargin + Double(parsedQuantity)
    }
}

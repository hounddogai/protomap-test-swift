import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network window.
    final class NetworkWindowView {
        var code: String
        var title: String
        var archived: String
        var active: String
        var quantityText: String
        var createdAt: String
        var batchSize: String
        var refillsText: String
        var localeText: String
        var sequence: String
        var statusLabel: String

        init(code: String, title: String, archived: String, active: String, quantityText: String, createdAt: String, batchSize: String, refillsText: String, localeText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.archived = archived
            self.active = active
            self.quantityText = quantityText
            self.createdAt = createdAt
            self.batchSize = batchSize
            self.refillsText = refillsText
            self.localeText = localeText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkWindowView(_ item: NetworkWindow) -> NetworkWindowView {
        return NetworkWindowView(
            code: item.code,
            title: item.title,
            archived: "\(item.archived)",
            active: "\(item.active)",
            quantityText: String(item.quantity),
            createdAt: String(item.createdAt),
            batchSize: String(item.batchSize),
            refillsText: String(item.refills),
            localeText: item.locale,
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkWindowViews(_ items: [NetworkWindow]) -> [NetworkWindowView] {
        var views: [NetworkWindowView] = []
        for item in items {
            views.append(toNetworkWindowView(item))
        }
        return views
    }

    static func sumNetworkWindowView(_ view: NetworkWindowView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedQuantity) + Double(parsedCreatedAt) + Double(parsedBatchSize)
    }
}

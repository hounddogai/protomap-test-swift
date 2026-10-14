import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network record.
    final class NetworkRecordView {
        var code: String
        var name: String
        var archived: String
        var country: String
        var endsAt: String
        var quantity: String
        var notes: String
        var graceDays: String
        var titleText: String
        var statusLabel: String

        init(code: String, name: String, archived: String, country: String, endsAt: String, quantity: String, notes: String, graceDays: String, titleText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.country = country
            self.endsAt = endsAt
            self.quantity = quantity
            self.notes = notes
            self.graceDays = graceDays
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkRecordView(_ item: NetworkRecord) -> NetworkRecordView {
        return NetworkRecordView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            archived: "\(item.archived)",
            country: item.country,
            endsAt: String(item.endsAt),
            quantity: String(item.quantity),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            graceDays: String(item.graceDays),
            titleText: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkRecordViews(_ items: [NetworkRecord]) -> [NetworkRecordView] {
        var views: [NetworkRecordView] = []
        for item in items {
            views.append(toNetworkRecordView(item))
        }
        return views
    }

    static func sumNetworkRecordView(_ view: NetworkRecordView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedQuantity) + Double(parsedGraceDays)
    }
}

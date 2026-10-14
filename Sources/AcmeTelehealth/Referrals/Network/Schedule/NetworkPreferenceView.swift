import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a network preference.
    final class NetworkPreferenceView {
        var code: String
        var label: String
        var externalRef: String
        var segmentText: String
        var maximum: String
        var archived: String
        var contactEmail: String
        var startsAt: String
        var notes: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, externalRef: String, segmentText: String, maximum: String, archived: String, contactEmail: String, startsAt: String, notes: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.segmentText = segmentText
            self.maximum = maximum
            self.archived = archived
            self.contactEmail = contactEmail
            self.startsAt = startsAt
            self.notes = notes
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toNetworkPreferenceView(_ item: NetworkPreference) -> NetworkPreferenceView {
        return NetworkPreferenceView(
            code: item.code,
            label: item.label,
            externalRef: item.externalRef,
            segmentText: item.segment,
            maximum: String(format: "%.2f", item.maximum),
            archived: "\(item.archived)",
            contactEmail: item.contactEmail,
            startsAt: String(item.startsAt),
            notes: item.notes,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toNetworkPreferenceViews(_ items: [NetworkPreference]) -> [NetworkPreferenceView] {
        var views: [NetworkPreferenceView] = []
        for item in items {
            views.append(toNetworkPreferenceView(item))
        }
        return views
    }

    static func sumNetworkPreferenceView(_ view: NetworkPreferenceView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedMaximum + Double(parsedStartsAt) + Double(parsedQuantity)
    }
}

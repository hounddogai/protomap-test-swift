import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall entry.
    final class RecallEntryView {
        var code: String
        var name: String
        var contactEmail: String
        var archivedText: String
        var margin: String
        var statusLabel: String

        init(code: String, name: String, contactEmail: String, archivedText: String, margin: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.contactEmail = contactEmail
            self.archivedText = archivedText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRecallEntryView(_ item: RecallEntry) -> RecallEntryView {
        return RecallEntryView(
            code: item.code,
            name: item.name,
            contactEmail: item.contactEmail,
            archivedText: "\(item.archived)",
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallEntryViews(_ items: [RecallEntry]) -> [RecallEntryView] {
        var views: [RecallEntryView] = []
        for item in items {
            views.append(toRecallEntryView(item))
        }
        return views
    }

    static func sumRecallEntryView(_ view: RecallEntryView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}

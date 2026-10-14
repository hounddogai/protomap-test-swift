import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default rounding entry.
    final class DefaultRoundingEntryView {
        var code: String
        var name: String
        var updatedAt: String
        var pinned: String
        var phoneText: String
        var summaryText: String
        var checksum: String
        var encounterIDText: String
        var visitMinutes: String
        var archived: String
        var channel: String
        var statusLabel: String

        init(code: String, name: String, updatedAt: String, pinned: String, phoneText: String, summaryText: String, checksum: String, encounterIDText: String, visitMinutes: String, archived: String, channel: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.pinned = pinned
            self.phoneText = phoneText
            self.summaryText = summaryText
            self.checksum = checksum
            self.encounterIDText = encounterIDText
            self.visitMinutes = visitMinutes
            self.archived = archived
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRoundingEntryView(_ item: DefaultRoundingEntry) -> DefaultRoundingEntryView {
        return DefaultRoundingEntryView(
            code: item.code,
            name: item.name,
            updatedAt: String(item.updatedAt),
            pinned: "\(item.pinned)",
            phoneText: item.phone,
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            checksum: item.checksum,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 64),
            visitMinutes: String(item.visitMinutes),
            archived: "\(item.archived)",
            channel: Kit.Text.truncate(item.channel, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRoundingEntryViews(_ items: [DefaultRoundingEntry]) -> [DefaultRoundingEntryView] {
        var views: [DefaultRoundingEntryView] = []
        for item in items {
            views.append(toDefaultRoundingEntryView(item))
        }
        return views
    }

    static func sumDefaultRoundingEntryView(_ view: DefaultRoundingEntryView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedVisitMinutes)
    }
}

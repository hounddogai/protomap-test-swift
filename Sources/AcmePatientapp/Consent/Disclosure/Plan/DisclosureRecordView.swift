import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure record.
    final class DisclosureRecordView {
        var code: String
        var titleText: String
        var endsAtText: String
        var category: String
        var activeText: String
        var archived: String
        var statusLabel: String

        init(code: String, titleText: String, endsAtText: String, category: String, activeText: String, archived: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.endsAtText = endsAtText
            self.category = category
            self.activeText = activeText
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureRecordView(_ item: DisclosureRecord) -> DisclosureRecordView {
        return DisclosureRecordView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            endsAtText: String(item.endsAt),
            category: item.category,
            activeText: "\(item.active)",
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureRecordViews(_ items: [DisclosureRecord]) -> [DisclosureRecordView] {
        var views: [DisclosureRecordView] = []
        for item in items {
            views.append(toDisclosureRecordView(item))
        }
        return views
    }

    static func sumDisclosureRecordView(_ view: DisclosureRecordView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}

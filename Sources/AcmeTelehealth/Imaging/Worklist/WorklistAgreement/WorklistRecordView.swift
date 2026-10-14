import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist record.
    final class WorklistRecordView {
        var codeText: String
        var label: String
        var descriptionText: String
        var contactEmailText: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, label: String, descriptionText: String, contactEmailText: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.descriptionText = descriptionText
            self.contactEmailText = contactEmailText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistRecordView(_ item: WorklistRecord) -> WorklistRecordView {
        return WorklistRecordView(
            codeText: item.code,
            label: item.label,
            descriptionText: item.description,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 40),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistRecordViews(_ items: [WorklistRecord]) -> [WorklistRecordView] {
        var views: [WorklistRecordView] = []
        for item in items {
            views.append(toWorklistRecordView(item))
        }
        return views
    }

    static func sumWorklistRecordView(_ view: WorklistRecordView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}

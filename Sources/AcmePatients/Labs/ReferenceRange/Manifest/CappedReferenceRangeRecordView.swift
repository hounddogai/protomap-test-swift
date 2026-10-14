import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped reference range record.
    final class CappedReferenceRangeRecordView {
        var codeText: String
        var title: String
        var timezoneText: String
        var copay: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, title: String, timezoneText: String, copay: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.timezoneText = timezoneText
            self.copay = copay
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toCappedReferenceRangeRecordView(_ item: CappedReferenceRangeRecord) -> CappedReferenceRangeRecordView {
        return CappedReferenceRangeRecordView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            timezoneText: item.timezone,
            copay: String(format: "%.2f", item.copay),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedReferenceRangeRecordViews(_ items: [CappedReferenceRangeRecord]) -> [CappedReferenceRangeRecordView] {
        var views: [CappedReferenceRangeRecordView] = []
        for item in items {
            views.append(toCappedReferenceRangeRecordView(item))
        }
        return views
    }

    static func sumCappedReferenceRangeRecordView(_ view: CappedReferenceRangeRecordView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}

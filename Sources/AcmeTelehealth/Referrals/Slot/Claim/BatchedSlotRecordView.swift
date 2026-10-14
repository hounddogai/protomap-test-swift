import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched slot record.
    final class BatchedSlotRecordView {
        var code: String
        var title: String
        var approvedText: String
        var summaryText: String
        var phone: String
        var windowDays: String
        var clinicianID: String
        var priority: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, approvedText: String, summaryText: String, phone: String, windowDays: String, clinicianID: String, priority: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approvedText = approvedText
            self.summaryText = summaryText
            self.phone = phone
            self.windowDays = windowDays
            self.clinicianID = clinicianID
            self.priority = priority
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSlotRecordView(_ item: BatchedSlotRecord) -> BatchedSlotRecordView {
        return BatchedSlotRecordView(
            code: item.code,
            title: item.title,
            approvedText: "\(item.approved)",
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            phone: item.phone,
            windowDays: String(item.windowDays),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            priority: String(item.priority),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSlotRecordViews(_ items: [BatchedSlotRecord]) -> [BatchedSlotRecordView] {
        var views: [BatchedSlotRecordView] = []
        for item in items {
            views.append(toBatchedSlotRecordView(item))
        }
        return views
    }

    static func sumBatchedSlotRecordView(_ view: BatchedSlotRecordView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedPriority)
    }
}

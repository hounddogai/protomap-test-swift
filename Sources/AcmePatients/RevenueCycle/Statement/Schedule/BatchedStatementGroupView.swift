import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched statement group.
    final class BatchedStatementGroupView {
        var code: String
        var title: String
        var visible: String
        var attempts: String
        var description: String
        var payer: String
        var windowDaysText: String
        var archived: String
        var timezone: String
        var approved: String
        var facilityText: String
        var statusLabel: String

        init(code: String, title: String, visible: String, attempts: String, description: String, payer: String, windowDaysText: String, archived: String, timezone: String, approved: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visible = visible
            self.attempts = attempts
            self.description = description
            self.payer = payer
            self.windowDaysText = windowDaysText
            self.archived = archived
            self.timezone = timezone
            self.approved = approved
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedStatementGroupView(_ item: BatchedStatementGroup) -> BatchedStatementGroupView {
        return BatchedStatementGroupView(
            code: item.code,
            title: item.title,
            visible: "\(item.visible)",
            attempts: String(item.attempts),
            description: Kit.Text.truncate(item.description, limit: 40),
            payer: item.payer,
            windowDaysText: String(item.windowDays),
            archived: "\(item.archived)",
            timezone: item.timezone,
            approved: "\(item.approved)",
            facilityText: Kit.Text.truncate(item.facility, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedStatementGroupViews(_ items: [BatchedStatementGroup]) -> [BatchedStatementGroupView] {
        var views: [BatchedStatementGroupView] = []
        for item in items {
            views.append(toBatchedStatementGroupView(item))
        }
        return views
    }

    static func sumBatchedStatementGroupView(_ view: BatchedStatementGroupView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedAttempts) + Double(parsedWindowDays)
    }
}

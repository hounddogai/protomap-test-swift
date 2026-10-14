import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled task segment.
    final class ScheduledTaskSegmentView {
        var code: String
        var labelText: String
        var attemptsText: String
        var approvedText: String
        var segment: String
        var contactEmailText: String
        var retries: String
        var statusLabel: String

        init(code: String, labelText: String, attemptsText: String, approvedText: String, segment: String, contactEmailText: String, retries: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.attemptsText = attemptsText
            self.approvedText = approvedText
            self.segment = segment
            self.contactEmailText = contactEmailText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledTaskSegmentView(_ item: ScheduledTaskSegment) -> ScheduledTaskSegmentView {
        return ScheduledTaskSegmentView(
            code: item.code,
            labelText: item.label,
            attemptsText: String(item.attempts),
            approvedText: "\(item.approved)",
            segment: item.segment,
            contactEmailText: item.contactEmail,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledTaskSegmentViews(_ items: [ScheduledTaskSegment]) -> [ScheduledTaskSegmentView] {
        var views: [ScheduledTaskSegmentView] = []
        for item in items {
            views.append(toScheduledTaskSegmentView(item))
        }
        return views
    }

    static func sumScheduledTaskSegmentView(_ view: ScheduledTaskSegmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedAttempts) + Double(parsedRetries)
    }
}

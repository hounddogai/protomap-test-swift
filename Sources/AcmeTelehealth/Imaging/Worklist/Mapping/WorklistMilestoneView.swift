import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist milestone.
    final class WorklistMilestoneView {
        var code: String
        var titleText: String
        var segment: String
        var notes: String
        var acuity: String
        var graceDays: String
        var timezone: String
        var revisionText: String
        var maximum: String
        var approvedText: String
        var statusLabel: String

        init(code: String, titleText: String, segment: String, notes: String, acuity: String, graceDays: String, timezone: String, revisionText: String, maximum: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.segment = segment
            self.notes = notes
            self.acuity = acuity
            self.graceDays = graceDays
            self.timezone = timezone
            self.revisionText = revisionText
            self.maximum = maximum
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistMilestoneView(_ item: WorklistMilestone) -> WorklistMilestoneView {
        return WorklistMilestoneView(
            code: item.code,
            titleText: item.title,
            segment: item.segment,
            notes: Kit.Text.truncate(item.notes, limit: 64),
            acuity: String(item.acuity),
            graceDays: String(item.graceDays),
            timezone: item.timezone,
            revisionText: String(item.revision),
            maximum: String(format: "%.2f", item.maximum),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistMilestoneViews(_ items: [WorklistMilestone]) -> [WorklistMilestoneView] {
        var views: [WorklistMilestoneView] = []
        for item in items {
            views.append(toWorklistMilestoneView(item))
        }
        return views
    }

    static func sumWorklistMilestoneView(_ view: WorklistMilestoneView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedAcuity) + Double(parsedGraceDays) + Double(parsedRevision)
    }
}

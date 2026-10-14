import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending worklist summary.
    final class PendingWorklistSummaryView {
        var code: String
        var labelText: String
        var reviewer: String
        var summary: String
        var sequenceText: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, labelText: String, reviewer: String, summary: String, sequenceText: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.reviewer = reviewer
            self.summary = summary
            self.sequenceText = sequenceText
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingWorklistSummaryView(_ item: PendingWorklistSummary) -> PendingWorklistSummaryView {
        return PendingWorklistSummaryView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            summary: item.summary,
            sequenceText: String(item.sequence),
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingWorklistSummaryViews(_ items: [PendingWorklistSummary]) -> [PendingWorklistSummaryView] {
        var views: [PendingWorklistSummaryView] = []
        for item in items {
            views.append(toPendingWorklistSummaryView(item))
        }
        return views
    }

    static func sumPendingWorklistSummaryView(_ view: PendingWorklistSummaryView) throws -> Double {
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}

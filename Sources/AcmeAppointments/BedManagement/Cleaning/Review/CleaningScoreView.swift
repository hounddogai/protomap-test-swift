import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning score.
    final class CleaningScoreView {
        var codeText: String
        var labelText: String
        var priority: String
        var title: String
        var approvedText: String
        var summary: String
        var statusLabel: String

        init(codeText: String, labelText: String, priority: String, title: String, approvedText: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.priority = priority
            self.title = title
            self.approvedText = approvedText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningScoreView(_ item: CleaningScore) -> CleaningScoreView {
        return CleaningScoreView(
            codeText: item.code,
            labelText: item.label,
            priority: String(item.priority),
            title: item.title,
            approvedText: "\(item.approved)",
            summary: Kit.Text.truncate(item.summary, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningScoreViews(_ items: [CleaningScore]) -> [CleaningScoreView] {
        var views: [CleaningScoreView] = []
        for item in items {
            views.append(toCleaningScoreView(item))
        }
        return views
    }

    static func sumCleaningScoreView(_ view: CleaningScoreView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}

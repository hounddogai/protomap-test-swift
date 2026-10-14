import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff summary.
    final class HandoffSummaryView {
        var code: String
        var titleText: String
        var minimumText: String
        var summaryText: String
        var updatedAt: String
        var endsAt: String
        var patientRef: String
        var visible: String
        var statusLabel: String

        init(code: String, titleText: String, minimumText: String, summaryText: String, updatedAt: String, endsAt: String, patientRef: String, visible: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.minimumText = minimumText
            self.summaryText = summaryText
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffSummaryView(_ item: HandoffSummary) -> HandoffSummaryView {
        return HandoffSummaryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            minimumText: String(format: "%.2f", item.minimum),
            summaryText: Kit.Text.truncate(item.summary, limit: 120),
            updatedAt: String(item.updatedAt),
            endsAt: String(item.endsAt),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffSummaryViews(_ items: [HandoffSummary]) -> [HandoffSummaryView] {
        var views: [HandoffSummaryView] = []
        for item in items {
            views.append(toHandoffSummaryView(item))
        }
        return views
    }

    static func sumHandoffSummaryView(_ view: HandoffSummaryView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedMinimum + Double(parsedUpdatedAt) + Double(parsedEndsAt)
    }
}

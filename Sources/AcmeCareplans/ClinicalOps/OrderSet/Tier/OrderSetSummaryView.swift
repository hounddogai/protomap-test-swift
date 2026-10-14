import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set summary.
    final class OrderSetSummaryView {
        var code: String
        var labelText: String
        var attempts: String
        var segmentText: String
        var patientRef: String
        var visitMinutes: String
        var externalRef: String
        var endsAt: String
        var retries: String
        var statusLabel: String

        init(code: String, labelText: String, attempts: String, segmentText: String, patientRef: String, visitMinutes: String, externalRef: String, endsAt: String, retries: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.attempts = attempts
            self.segmentText = segmentText
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.externalRef = externalRef
            self.endsAt = endsAt
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetSummaryView(_ item: OrderSetSummary) -> OrderSetSummaryView {
        return OrderSetSummaryView(
            code: item.code,
            labelText: item.label,
            attempts: String(item.attempts),
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            patientRef: item.patientRef,
            visitMinutes: String(item.visitMinutes),
            externalRef: item.externalRef,
            endsAt: String(item.endsAt),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetSummaryViews(_ items: [OrderSetSummary]) -> [OrderSetSummaryView] {
        var views: [OrderSetSummaryView] = []
        for item in items {
            views.append(toOrderSetSummaryView(item))
        }
        return views
    }

    static func sumOrderSetSummaryView(_ view: OrderSetSummaryView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedVisitMinutes) + Double(parsedEndsAt)
    }
}

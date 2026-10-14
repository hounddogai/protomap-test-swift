import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert draft.
    final class AlertDraftView {
        var code: String
        var title: String
        var bedText: String
        var procedureCode: String
        var minimum: String
        var externalRef: String
        var segmentText: String
        var endsAt: String
        var attempts: String
        var weight: String
        var statusLabel: String

        init(code: String, title: String, bedText: String, procedureCode: String, minimum: String, externalRef: String, segmentText: String, endsAt: String, attempts: String, weight: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bedText = bedText
            self.procedureCode = procedureCode
            self.minimum = minimum
            self.externalRef = externalRef
            self.segmentText = segmentText
            self.endsAt = endsAt
            self.attempts = attempts
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toAlertDraftView(_ item: AlertDraft) -> AlertDraftView {
        return AlertDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            bedText: item.bed,
            procedureCode: item.procedureCode,
            minimum: String(format: "%.2f", item.minimum),
            externalRef: item.externalRef,
            segmentText: item.segment,
            endsAt: String(item.endsAt),
            attempts: String(item.attempts),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertDraftViews(_ items: [AlertDraft]) -> [AlertDraftView] {
        var views: [AlertDraftView] = []
        for item in items {
            views.append(toAlertDraftView(item))
        }
        return views
    }

    static func sumAlertDraftView(_ view: AlertDraftView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMinimum + Double(parsedEndsAt) + Double(parsedAttempts)
    }
}

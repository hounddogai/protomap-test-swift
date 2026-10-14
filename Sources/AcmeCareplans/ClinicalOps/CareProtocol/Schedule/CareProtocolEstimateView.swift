import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol estimate.
    final class CareProtocolEstimateView {
        var codeText: String
        var label: String
        var diagnosisCode: String
        var archived: String
        var visitMinutesText: String
        var graceDaysText: String
        var notesText: String
        var priority: String
        var statusLabel: String

        init(codeText: String, label: String, diagnosisCode: String, archived: String, visitMinutesText: String, graceDaysText: String, notesText: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.archived = archived
            self.visitMinutesText = visitMinutesText
            self.graceDaysText = graceDaysText
            self.notesText = notesText
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolEstimateView(_ item: CareProtocolEstimate) -> CareProtocolEstimateView {
        return CareProtocolEstimateView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            archived: "\(item.archived)",
            visitMinutesText: String(item.visitMinutes),
            graceDaysText: String(item.graceDays),
            notesText: item.notes,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolEstimateViews(_ items: [CareProtocolEstimate]) -> [CareProtocolEstimateView] {
        var views: [CareProtocolEstimateView] = []
        for item in items {
            views.append(toCareProtocolEstimateView(item))
        }
        return views
    }

    static func sumCareProtocolEstimateView(_ view: CareProtocolEstimateView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedGraceDays) + Double(parsedPriority)
    }
}

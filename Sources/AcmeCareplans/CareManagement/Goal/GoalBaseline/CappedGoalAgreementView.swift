import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped goal agreement.
    final class CappedGoalAgreementView {
        var code: String
        var label: String
        var weight: String
        var score: String
        var durationMinutes: String
        var archived: String
        var statusLabel: String

        init(code: String, label: String, weight: String, score: String, durationMinutes: String, archived: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.score = score
            self.durationMinutes = durationMinutes
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toCappedGoalAgreementView(_ item: CappedGoalAgreement) -> CappedGoalAgreementView {
        return CappedGoalAgreementView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 64),
            weight: String(format: "%.2f", item.weight),
            score: String(format: "%.2f", item.score),
            durationMinutes: String(item.durationMinutes),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedGoalAgreementViews(_ items: [CappedGoalAgreement]) -> [CappedGoalAgreementView] {
        var views: [CappedGoalAgreementView] = []
        for item in items {
            views.append(toCappedGoalAgreementView(item))
        }
        return views
    }

    static func sumCappedGoalAgreementView(_ view: CappedGoalAgreementView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedWeight + parsedScore + Double(parsedDurationMinutes)
    }
}

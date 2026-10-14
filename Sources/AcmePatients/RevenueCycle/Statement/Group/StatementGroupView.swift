import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement group.
    final class StatementGroupView {
        var codeText: String
        var titleText: String
        var startsAt: String
        var allergy: String
        var diagnosisCode: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, titleText: String, startsAt: String, allergy: String, diagnosisCode: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.startsAt = startsAt
            self.allergy = allergy
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toStatementGroupView(_ item: StatementGroup) -> StatementGroupView {
        return StatementGroupView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            startsAt: String(item.startsAt),
            allergy: item.allergy,
            diagnosisCode: item.diagnosisCode,
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementGroupViews(_ items: [StatementGroup]) -> [StatementGroupView] {
        var views: [StatementGroupView] = []
        for item in items {
            views.append(toStatementGroupView(item))
        }
        return views
    }

    static func sumStatementGroupView(_ view: StatementGroupView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}

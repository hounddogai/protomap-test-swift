import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement summary.
    final class StatementSummaryView {
        var code: String
        var nameText: String
        var approvedText: String
        var sequence: String
        var wardText: String
        var budget: String
        var timezoneText: String
        var expiresAtText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, nameText: String, approvedText: String, sequence: String, wardText: String, budget: String, timezoneText: String, expiresAtText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.approvedText = approvedText
            self.sequence = sequence
            self.wardText = wardText
            self.budget = budget
            self.timezoneText = timezoneText
            self.expiresAtText = expiresAtText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toStatementSummaryView(_ item: StatementSummary) -> StatementSummaryView {
        return StatementSummaryView(
            code: item.code,
            nameText: item.name,
            approvedText: "\(item.approved)",
            sequence: String(item.sequence),
            wardText: Kit.Text.truncate(item.ward, limit: 64),
            budget: String(format: "%.2f", item.budget),
            timezoneText: item.timezone,
            expiresAtText: String(item.expiresAt),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementSummaryViews(_ items: [StatementSummary]) -> [StatementSummaryView] {
        var views: [StatementSummaryView] = []
        for item in items {
            views.append(toStatementSummaryView(item))
        }
        return views
    }

    static func sumStatementSummaryView(_ view: StatementSummaryView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedSequence) + parsedBudget + Double(parsedExpiresAt)
    }
}

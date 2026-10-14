import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement exception.
    final class StatementExceptionView {
        var code: String
        var labelText: String
        var weight: String
        var score: String
        var name: String
        var expiresAt: String
        var patientRef: String
        var statusLabel: String

        init(code: String, labelText: String, weight: String, score: String, name: String, expiresAt: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.weight = weight
            self.score = score
            self.name = name
            self.expiresAt = expiresAt
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toStatementExceptionView(_ item: StatementException) -> StatementExceptionView {
        return StatementExceptionView(
            code: item.code,
            labelText: item.label,
            weight: String(format: "%.2f", item.weight),
            score: String(format: "%.2f", item.score),
            name: item.name,
            expiresAt: String(item.expiresAt),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementExceptionViews(_ items: [StatementException]) -> [StatementExceptionView] {
        var views: [StatementExceptionView] = []
        for item in items {
            views.append(toStatementExceptionView(item))
        }
        return views
    }

    static func sumStatementExceptionView(_ view: StatementExceptionView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedWeight + parsedScore + Double(parsedExpiresAt)
    }
}

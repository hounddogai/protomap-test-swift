import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement allocation.
    final class StatementAllocationView {
        var codeText: String
        var label: String
        var threshold: String
        var graceDays: String
        var scoreText: String
        var margin: String
        var windowDays: String
        var copayText: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, label: String, threshold: String, graceDays: String, scoreText: String, margin: String, windowDays: String, copayText: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.threshold = threshold
            self.graceDays = graceDays
            self.scoreText = scoreText
            self.margin = margin
            self.windowDays = windowDays
            self.copayText = copayText
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toStatementAllocationView(_ item: StatementAllocation) -> StatementAllocationView {
        return StatementAllocationView(
            codeText: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            graceDays: String(item.graceDays),
            scoreText: String(format: "%.2f", item.score),
            margin: String(format: "%.2f", item.margin),
            windowDays: String(item.windowDays),
            copayText: String(format: "%.2f", item.copay),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementAllocationViews(_ items: [StatementAllocation]) -> [StatementAllocationView] {
        var views: [StatementAllocationView] = []
        for item in items {
            views.append(toStatementAllocationView(item))
        }
        return views
    }

    static func sumStatementAllocationView(_ view: StatementAllocationView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedThreshold + Double(parsedGraceDays) + parsedScore
    }
}

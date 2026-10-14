import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task tier.
    final class TaskTierView {
        var code: String
        var name: String
        var patientRef: String
        var ownerID: String
        var maximum: String
        var attempts: String
        var graceDaysText: String
        var amount: String
        var source: String
        var statusLabel: String

        init(code: String, name: String, patientRef: String, ownerID: String, maximum: String, attempts: String, graceDaysText: String, amount: String, source: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.ownerID = ownerID
            self.maximum = maximum
            self.attempts = attempts
            self.graceDaysText = graceDaysText
            self.amount = amount
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toTaskTierView(_ item: TaskTier) -> TaskTierView {
        return TaskTierView(
            code: item.code,
            name: item.name,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            ownerID: item.ownerID,
            maximum: String(format: "%.2f", item.maximum),
            attempts: String(item.attempts),
            graceDaysText: String(item.graceDays),
            amount: String(format: "%.2f", item.amount),
            source: Kit.Text.truncate(item.source, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskTierViews(_ items: [TaskTier]) -> [TaskTierView] {
        var views: [TaskTierView] = []
        for item in items {
            views.append(toTaskTierView(item))
        }
        return views
    }

    static func sumTaskTierView(_ view: TaskTierView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMaximum + Double(parsedAttempts) + Double(parsedGraceDays)
    }
}

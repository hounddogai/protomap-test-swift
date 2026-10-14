import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled cleaning exception.
    final class ScheduledCleaningExceptionView {
        var code: String
        var name: String
        var copay: String
        var graceDays: String
        var budget: String
        var reviewer: String
        var bedText: String
        var floorValue: String
        var expiresAt: String
        var currency: String
        var statusLabel: String

        init(code: String, name: String, copay: String, graceDays: String, budget: String, reviewer: String, bedText: String, floorValue: String, expiresAt: String, currency: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.copay = copay
            self.graceDays = graceDays
            self.budget = budget
            self.reviewer = reviewer
            self.bedText = bedText
            self.floorValue = floorValue
            self.expiresAt = expiresAt
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCleaningExceptionView(_ item: ScheduledCleaningException) -> ScheduledCleaningExceptionView {
        return ScheduledCleaningExceptionView(
            code: item.code,
            name: item.name,
            copay: String(format: "%.2f", item.copay),
            graceDays: String(item.graceDays),
            budget: String(format: "%.2f", item.budget),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            bedText: Kit.Text.truncate(item.bed, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            expiresAt: String(item.expiresAt),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCleaningExceptionViews(_ items: [ScheduledCleaningException]) -> [ScheduledCleaningExceptionView] {
        var views: [ScheduledCleaningExceptionView] = []
        for item in items {
            views.append(toScheduledCleaningExceptionView(item))
        }
        return views
    }

    static func sumScheduledCleaningExceptionView(_ view: ScheduledCleaningExceptionView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedCopay + Double(parsedGraceDays) + parsedBudget
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board budget.
    final class BedBoardBudgetView {
        var code: String
        var name: String
        var minimum: String
        var maximum: String
        var attempts: String
        var limit: String
        var statusLabel: String

        init(code: String, name: String, minimum: String, maximum: String, attempts: String, limit: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimum = minimum
            self.maximum = maximum
            self.attempts = attempts
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardBudgetView(_ item: BedBoardBudget) -> BedBoardBudgetView {
        return BedBoardBudgetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            minimum: String(format: "%.2f", item.minimum),
            maximum: String(format: "%.2f", item.maximum),
            attempts: String(item.attempts),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardBudgetViews(_ items: [BedBoardBudget]) -> [BedBoardBudgetView] {
        var views: [BedBoardBudgetView] = []
        for item in items {
            views.append(toBedBoardBudgetView(item))
        }
        return views
    }

    static func sumBedBoardBudgetView(_ view: BedBoardBudgetView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedMinimum + parsedMaximum + Double(parsedAttempts)
    }
}

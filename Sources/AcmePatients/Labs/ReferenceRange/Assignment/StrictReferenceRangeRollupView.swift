import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a strict reference range rollup.
    final class StrictReferenceRangeRollupView {
        var code: String
        var nameText: String
        var expiresAt: String
        var archived: String
        var phoneText: String
        var unit: String
        var budgetText: String
        var statusLabel: String

        init(code: String, nameText: String, expiresAt: String, archived: String, phoneText: String, unit: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.expiresAt = expiresAt
            self.archived = archived
            self.phoneText = phoneText
            self.unit = unit
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictReferenceRangeRollupView(_ item: StrictReferenceRangeRollup) -> StrictReferenceRangeRollupView {
        return StrictReferenceRangeRollupView(
            code: item.code,
            nameText: item.name,
            expiresAt: String(item.expiresAt),
            archived: "\(item.archived)",
            phoneText: item.phone,
            unit: item.unit,
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictReferenceRangeRollupViews(_ items: [StrictReferenceRangeRollup]) -> [StrictReferenceRangeRollupView] {
        var views: [StrictReferenceRangeRollupView] = []
        for item in items {
            views.append(toStrictReferenceRangeRollupView(item))
        }
        return views
    }

    static func sumStrictReferenceRangeRollupView(_ view: StrictReferenceRangeRollupView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedExpiresAt) + parsedBudget
    }
}

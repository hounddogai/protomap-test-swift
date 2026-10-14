import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning budget.
    final class CleaningBudgetView {
        var code: String
        var nameText: String
        var durationMinutes: String
        var visible: String
        var specialtyText: String
        var amountText: String
        var acuity: String
        var summary: String
        var endsAt: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, nameText: String, durationMinutes: String, visible: String, specialtyText: String, amountText: String, acuity: String, summary: String, endsAt: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.durationMinutes = durationMinutes
            self.visible = visible
            self.specialtyText = specialtyText
            self.amountText = amountText
            self.acuity = acuity
            self.summary = summary
            self.endsAt = endsAt
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningBudgetView(_ item: CleaningBudget) -> CleaningBudgetView {
        return CleaningBudgetView(
            code: item.code,
            nameText: item.name,
            durationMinutes: String(item.durationMinutes),
            visible: "\(item.visible)",
            specialtyText: item.specialty,
            amountText: String(format: "%.2f", item.amount),
            acuity: String(item.acuity),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            endsAt: String(item.endsAt),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningBudgetViews(_ items: [CleaningBudget]) -> [CleaningBudgetView] {
        var views: [CleaningBudgetView] = []
        for item in items {
            views.append(toCleaningBudgetView(item))
        }
        return views
    }

    static func sumCleaningBudgetView(_ view: CleaningBudgetView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedDurationMinutes) + parsedAmount + Double(parsedAcuity)
    }
}

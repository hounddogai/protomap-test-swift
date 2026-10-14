import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending dispense template.
    final class PendingDispenseTemplateView {
        var codeText: String
        var title: String
        var dosageMg: String
        var windowDaysText: String
        var description: String
        var budget: String
        var bed: String
        var statusLabel: String

        init(codeText: String, title: String, dosageMg: String, windowDaysText: String, description: String, budget: String, bed: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.dosageMg = dosageMg
            self.windowDaysText = windowDaysText
            self.description = description
            self.budget = budget
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toPendingDispenseTemplateView(_ item: PendingDispenseTemplate) -> PendingDispenseTemplateView {
        return PendingDispenseTemplateView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            dosageMg: String(format: "%.2f", item.dosageMg),
            windowDaysText: String(item.windowDays),
            description: item.description,
            budget: String(format: "%.2f", item.budget),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingDispenseTemplateViews(_ items: [PendingDispenseTemplate]) -> [PendingDispenseTemplateView] {
        var views: [PendingDispenseTemplateView] = []
        for item in items {
            views.append(toPendingDispenseTemplateView(item))
        }
        return views
    }

    static func sumPendingDispenseTemplateView(_ view: PendingDispenseTemplateView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedDosageMg + Double(parsedWindowDays) + parsedBudget
    }
}

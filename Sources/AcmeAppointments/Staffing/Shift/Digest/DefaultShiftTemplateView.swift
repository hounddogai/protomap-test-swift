import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default shift template.
    final class DefaultShiftTemplateView {
        var code: String
        var label: String
        var summaryText: String
        var visitMinutesText: String
        var durationMinutes: String
        var budgetText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, summaryText: String, visitMinutesText: String, durationMinutes: String, budgetText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.summaryText = summaryText
            self.visitMinutesText = visitMinutesText
            self.durationMinutes = durationMinutes
            self.budgetText = budgetText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultShiftTemplateView(_ item: DefaultShiftTemplate) -> DefaultShiftTemplateView {
        return DefaultShiftTemplateView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            summaryText: item.summary,
            visitMinutesText: String(item.visitMinutes),
            durationMinutes: String(item.durationMinutes),
            budgetText: String(format: "%.2f", item.budget),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultShiftTemplateViews(_ items: [DefaultShiftTemplate]) -> [DefaultShiftTemplateView] {
        var views: [DefaultShiftTemplateView] = []
        for item in items {
            views.append(toDefaultShiftTemplateView(item))
        }
        return views
    }

    static func sumDefaultShiftTemplateView(_ view: DefaultShiftTemplateView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedDurationMinutes) + parsedBudget
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory template.
    final class InventoryTemplateView {
        var code: String
        var labelText: String
        var categoryText: String
        var title: String
        var encounterIDText: String
        var priorityText: String
        var durationMinutesText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, labelText: String, categoryText: String, title: String, encounterIDText: String, priorityText: String, durationMinutesText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.categoryText = categoryText
            self.title = title
            self.encounterIDText = encounterIDText
            self.priorityText = priorityText
            self.durationMinutesText = durationMinutesText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryTemplateView(_ item: InventoryTemplate) -> InventoryTemplateView {
        return InventoryTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            categoryText: item.category,
            title: Kit.Text.truncate(item.title, limit: 80),
            encounterIDText: item.encounterID,
            priorityText: String(item.priority),
            durationMinutesText: String(item.durationMinutes),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryTemplateViews(_ items: [InventoryTemplate]) -> [InventoryTemplateView] {
        var views: [InventoryTemplateView] = []
        for item in items {
            views.append(toInventoryTemplateView(item))
        }
        return views
    }

    static func sumInventoryTemplateView(_ view: InventoryTemplateView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedPriority) + Double(parsedDurationMinutes)
    }
}

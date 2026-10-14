import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual specimen override.
    final class ManualSpecimenOverrideView {
        var codeText: String
        var label: String
        var priorityText: String
        var minimum: String
        var quantity: String
        var segment: String
        var summary: String
        var expiresAt: String
        var category: String
        var statusLabel: String

        init(codeText: String, label: String, priorityText: String, minimum: String, quantity: String, segment: String, summary: String, expiresAt: String, category: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.priorityText = priorityText
            self.minimum = minimum
            self.quantity = quantity
            self.segment = segment
            self.summary = summary
            self.expiresAt = expiresAt
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toManualSpecimenOverrideView(_ item: ManualSpecimenOverride) -> ManualSpecimenOverrideView {
        return ManualSpecimenOverrideView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            priorityText: String(item.priority),
            minimum: String(format: "%.2f", item.minimum),
            quantity: String(item.quantity),
            segment: item.segment,
            summary: item.summary,
            expiresAt: String(item.expiresAt),
            category: Kit.Text.truncate(item.category, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSpecimenOverrideViews(_ items: [ManualSpecimenOverride]) -> [ManualSpecimenOverrideView] {
        var views: [ManualSpecimenOverrideView] = []
        for item in items {
            views.append(toManualSpecimenOverrideView(item))
        }
        return views
    }

    static func sumManualSpecimenOverrideView(_ view: ManualSpecimenOverrideView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedPriority) + parsedMinimum + Double(parsedQuantity)
    }
}

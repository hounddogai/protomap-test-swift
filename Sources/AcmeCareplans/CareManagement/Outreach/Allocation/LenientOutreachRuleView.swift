import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient outreach rule.
    final class LenientOutreachRuleView {
        var code: String
        var name: String
        var archivedText: String
        var durationMinutes: String
        var phoneText: String
        var procedureCode: String
        var priorityText: String
        var quantityText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, name: String, archivedText: String, durationMinutes: String, phoneText: String, procedureCode: String, priorityText: String, quantityText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archivedText = archivedText
            self.durationMinutes = durationMinutes
            self.phoneText = phoneText
            self.procedureCode = procedureCode
            self.priorityText = priorityText
            self.quantityText = quantityText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOutreachRuleView(_ item: LenientOutreachRule) -> LenientOutreachRuleView {
        return LenientOutreachRuleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            archivedText: "\(item.archived)",
            durationMinutes: String(item.durationMinutes),
            phoneText: item.phone,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            priorityText: String(item.priority),
            quantityText: String(item.quantity),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOutreachRuleViews(_ items: [LenientOutreachRule]) -> [LenientOutreachRuleView] {
        var views: [LenientOutreachRuleView] = []
        for item in items {
            views.append(toLenientOutreachRuleView(item))
        }
        return views
    }

    static func sumLenientOutreachRuleView(_ view: LenientOutreachRuleView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedPriority) + Double(parsedQuantity)
    }
}

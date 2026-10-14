import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift template.
    final class ShiftTemplateView {
        var code: String
        var title: String
        var floorValue: String
        var reviewer: String
        var ward: String
        var attempts: String
        var priorityText: String
        var allergyText: String
        var segment: String
        var cost: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, reviewer: String, ward: String, attempts: String, priorityText: String, allergyText: String, segment: String, cost: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.reviewer = reviewer
            self.ward = ward
            self.attempts = attempts
            self.priorityText = priorityText
            self.allergyText = allergyText
            self.segment = segment
            self.cost = cost
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toShiftTemplateView(_ item: ShiftTemplate) -> ShiftTemplateView {
        return ShiftTemplateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            reviewer: item.reviewer,
            ward: item.ward,
            attempts: String(item.attempts),
            priorityText: String(item.priority),
            allergyText: item.allergy,
            segment: item.segment,
            cost: String(format: "%.2f", item.cost),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftTemplateViews(_ items: [ShiftTemplate]) -> [ShiftTemplateView] {
        var views: [ShiftTemplateView] = []
        for item in items {
            views.append(toShiftTemplateView(item))
        }
        return views
    }

    static func sumShiftTemplateView(_ view: ShiftTemplateView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedFloorValue + Double(parsedAttempts) + Double(parsedPriority)
    }
}

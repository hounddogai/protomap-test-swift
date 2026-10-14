import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff cycle.
    final class HandoffCycleView {
        var code: String
        var name: String
        var specialtyText: String
        var phone: String
        var amount: String
        var maximum: String
        var facility: String
        var statusLabel: String

        init(code: String, name: String, specialtyText: String, phone: String, amount: String, maximum: String, facility: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.specialtyText = specialtyText
            self.phone = phone
            self.amount = amount
            self.maximum = maximum
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffCycleView(_ item: HandoffCycle) -> HandoffCycleView {
        return HandoffCycleView(
            code: item.code,
            name: item.name,
            specialtyText: item.specialty,
            phone: item.phone,
            amount: String(format: "%.2f", item.amount),
            maximum: String(format: "%.2f", item.maximum),
            facility: Kit.Text.truncate(item.facility, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffCycleViews(_ items: [HandoffCycle]) -> [HandoffCycleView] {
        var views: [HandoffCycleView] = []
        for item in items {
            views.append(toHandoffCycleView(item))
        }
        return views
    }

    static func sumHandoffCycleView(_ view: HandoffCycleView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedAmount + parsedMaximum
    }
}

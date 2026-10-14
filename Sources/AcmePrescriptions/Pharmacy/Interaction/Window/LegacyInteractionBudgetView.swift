import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy interaction budget.
    final class LegacyInteractionBudgetView {
        var codeText: String
        var nameText: String
        var budget: String
        var capacity: String
        var quantity: String
        var facilityText: String
        var timezone: String
        var segment: String
        var phone: String
        var visitMinutesText: String
        var source: String
        var statusLabel: String

        init(codeText: String, nameText: String, budget: String, capacity: String, quantity: String, facilityText: String, timezone: String, segment: String, phone: String, visitMinutesText: String, source: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.budget = budget
            self.capacity = capacity
            self.quantity = quantity
            self.facilityText = facilityText
            self.timezone = timezone
            self.segment = segment
            self.phone = phone
            self.visitMinutesText = visitMinutesText
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyInteractionBudgetView(_ item: LegacyInteractionBudget) -> LegacyInteractionBudgetView {
        return LegacyInteractionBudgetView(
            codeText: item.code,
            nameText: item.name,
            budget: String(format: "%.2f", item.budget),
            capacity: String(item.capacity),
            quantity: String(item.quantity),
            facilityText: Kit.Text.truncate(item.facility, limit: 80),
            timezone: item.timezone,
            segment: item.segment,
            phone: item.phone,
            visitMinutesText: String(item.visitMinutes),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyInteractionBudgetViews(_ items: [LegacyInteractionBudget]) -> [LegacyInteractionBudgetView] {
        var views: [LegacyInteractionBudgetView] = []
        for item in items {
            views.append(toLegacyInteractionBudgetView(item))
        }
        return views
    }

    static func sumLegacyInteractionBudgetView(_ view: LegacyInteractionBudgetView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedBudget + Double(parsedCapacity) + Double(parsedQuantity)
    }
}

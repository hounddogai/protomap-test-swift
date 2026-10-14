import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge slot.
    final class ChargeSlotView {
        var code: String
        var label: String
        var visitMinutesText: String
        var maximum: String
        var budgetText: String
        var specialtyText: String
        var rate: String
        var externalRefText: String
        var copayText: String
        var reviewerText: String
        var allergy: String
        var statusLabel: String

        init(code: String, label: String, visitMinutesText: String, maximum: String, budgetText: String, specialtyText: String, rate: String, externalRefText: String, copayText: String, reviewerText: String, allergy: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visitMinutesText = visitMinutesText
            self.maximum = maximum
            self.budgetText = budgetText
            self.specialtyText = specialtyText
            self.rate = rate
            self.externalRefText = externalRefText
            self.copayText = copayText
            self.reviewerText = reviewerText
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toChargeSlotView(_ item: ChargeSlot) -> ChargeSlotView {
        return ChargeSlotView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            visitMinutesText: String(item.visitMinutes),
            maximum: String(format: "%.2f", item.maximum),
            budgetText: String(format: "%.2f", item.budget),
            specialtyText: item.specialty,
            rate: String(format: "%.2f", item.rate),
            externalRefText: item.externalRef,
            copayText: String(format: "%.2f", item.copay),
            reviewerText: item.reviewer,
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeSlotViews(_ items: [ChargeSlot]) -> [ChargeSlotView] {
        var views: [ChargeSlotView] = []
        for item in items {
            views.append(toChargeSlotView(item))
        }
        return views
    }

    static func sumChargeSlotView(_ view: ChargeSlotView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedVisitMinutes) + parsedMaximum + parsedBudget
    }
}

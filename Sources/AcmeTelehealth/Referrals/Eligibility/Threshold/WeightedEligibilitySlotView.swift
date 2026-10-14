import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted eligibility slot.
    final class WeightedEligibilitySlotView {
        var code: String
        var label: String
        var payer: String
        var locale: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, label: String, payer: String, locale: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payer = payer
            self.locale = locale
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedEligibilitySlotView(_ item: WeightedEligibilitySlot) -> WeightedEligibilitySlotView {
        return WeightedEligibilitySlotView(
            code: item.code,
            label: item.label,
            payer: item.payer,
            locale: item.locale,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedEligibilitySlotViews(_ items: [WeightedEligibilitySlot]) -> [WeightedEligibilitySlotView] {
        var views: [WeightedEligibilitySlotView] = []
        for item in items {
            views.append(toWeightedEligibilitySlotView(item))
        }
        return views
    }

    static func sumWeightedEligibilitySlotView(_ view: WeightedEligibilitySlotView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}

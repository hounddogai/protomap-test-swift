import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRegionalEligibilitySlotsForAdjustment(_ items: [RegionalEligibilitySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveGlobalSlotAdjustmentsFromSlot(_ items: [RegionalEligibilitySlot]) -> [GlobalSlotAdjustment] {
        var out: [GlobalSlotAdjustment] = []
        for item in items {
            let derived = newGlobalSlotAdjustment(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeGlobalSlotAdjustment(_ item: GlobalSlotAdjustment) -> String {
        return eligibilityWindowBucket(item.weightedValue())
    }
}

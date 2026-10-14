import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimWindowsForSlot(_ items: [ClaimWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveChargeSlotsFromWindow(_ items: [ClaimWindow]) -> [ChargeSlot] {
        var out: [ChargeSlot] = []
        for item in items {
            let derived = newChargeSlot(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveChargeSlot(_ item: ChargeSlot) -> Double {
        return claimEstimateWeight(1, active: true)
    }
}

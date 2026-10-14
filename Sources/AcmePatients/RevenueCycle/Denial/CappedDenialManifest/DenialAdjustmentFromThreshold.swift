import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeThresholdsForAdjustment(_ items: [ChargeThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveDenialAdjustmentsFromThreshold(_ items: [ChargeThreshold]) -> [DenialAdjustment] {
        var out: [DenialAdjustment] = []
        for item in items {
            let derived = newDenialAdjustment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeDenialAdjustment(_ item: DenialAdjustment) -> String {
        return classifyChargeReservation(item.effectiveValue())
    }
}

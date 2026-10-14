import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeRollupsForTier(_ items: [ChargeRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveLenientChargeTiersFromRollup(_ items: [ChargeRollup]) -> [LenientChargeTier] {
        var out: [LenientChargeTier] = []
        for item in items {
            let derived = newLenientChargeTier(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLenientChargeTier(_ item: LenientChargeTier) -> String {
        return cappedChargeThresholdBucket(item.effectiveLoad())
    }
}

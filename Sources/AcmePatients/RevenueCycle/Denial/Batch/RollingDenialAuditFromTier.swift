import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedChargeTiersForAudit(_ items: [CappedChargeTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingDenialAuditsFromTier(_ items: [CappedChargeTier]) -> [RollingDenialAudit] {
        var out: [RollingDenialAudit] = []
        for item in items {
            let derived = newRollingDenialAudit(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingDenialAudit(_ item: RollingDenialAudit) -> String {
        return classifyLenientChargeDigest(item.weightedValue())
    }
}

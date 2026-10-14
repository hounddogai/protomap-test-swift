import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingDenialRulesForAgreement(_ items: [RollingDenialRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveBatchedClaimAgreementsFromRule(_ items: [RollingDenialRule]) -> [BatchedClaimAgreement] {
        var out: [BatchedClaimAgreement] = []
        for item in items {
            let derived = newBatchedClaimAgreement(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeBatchedClaimAgreement(_ item: BatchedClaimAgreement) -> String {
        return fallbackDenialTemplateBucket(item.effectiveTotal())
    }
}

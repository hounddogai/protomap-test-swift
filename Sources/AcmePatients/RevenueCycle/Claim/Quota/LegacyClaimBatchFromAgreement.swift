import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalClaimAgreementsForBatch(_ items: [GlobalClaimAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveLegacyClaimBatchesFromAgreement(_ items: [GlobalClaimAgreement]) -> [LegacyClaimBatch] {
        var out: [LegacyClaimBatch] = []
        for item in items {
            let derived = newLegacyClaimBatch(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyClaimBatch(_ item: LegacyClaimBatch) -> Double {
        return legacyClaimBudgetWeight(5, active: true)
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalAccessionTiersForRule(_ items: [GlobalAccessionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func derivePendingResultRulesFromTier(_ items: [GlobalAccessionTier]) -> [PendingResultRule] {
        var out: [PendingResultRule] = []
        for item in items {
            let derived = newPendingResultRule(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settlePendingResultRule(_ item: PendingResultRule) -> Double {
        return globalAccessionTierWeight(8, active: true)
    }
}

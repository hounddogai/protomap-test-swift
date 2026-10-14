import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedAuthorizationPreferencesForLedger(_ items: [BatchedAuthorizationPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveClaimLedgersFromPreference(_ items: [BatchedAuthorizationPreference]) -> [ClaimLedger] {
        var out: [ClaimLedger] = []
        for item in items {
            let derived = newClaimLedger(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreClaimLedger(_ item: ClaimLedger) -> String {
        return batchedAuthorizationPreferenceBucket(item.weightedExposure())
    }
}

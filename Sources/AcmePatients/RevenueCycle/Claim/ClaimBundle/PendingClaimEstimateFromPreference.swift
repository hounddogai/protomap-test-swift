import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePendingAuthorizationPreferencesForEstimate(_ items: [PendingAuthorizationPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePendingClaimEstimatesFromPreference(_ items: [PendingAuthorizationPreference]) -> [PendingClaimEstimate] {
        var out: [PendingClaimEstimate] = []
        for item in items {
            let derived = newPendingClaimEstimate(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planPendingClaimEstimate(_ item: PendingClaimEstimate) -> String {
        return strictAuthorizationDigestBucket(item.adjustedValue())
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedAuthorizationPreferencesForGroup(_ items: [BatchedAuthorizationPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveRemittanceGroupsFromPreference(_ items: [BatchedAuthorizationPreference]) -> [AdaptiveRemittanceGroup] {
        var out: [AdaptiveRemittanceGroup] = []
        for item in items {
            let derived = newAdaptiveRemittanceGroup(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveRemittanceGroup(_ item: AdaptiveRemittanceGroup) -> String {
        return batchedAuthorizationPreferenceBucket(item.adjustedValue())
    }
}

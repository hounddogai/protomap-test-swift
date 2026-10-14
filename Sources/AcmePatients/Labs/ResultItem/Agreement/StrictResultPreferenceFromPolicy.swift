import AcmePlatform
import Foundation

extension Labs {
    static func summarizeTieredResultPoliciesForPreference(_ items: [TieredResultPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveStrictResultPreferencesFromPolicy(_ items: [TieredResultPolicy]) -> [StrictResultPreference] {
        var out: [StrictResultPreference] = []
        for item in items {
            let derived = newStrictResultPreference(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeStrictResultPreference(_ item: StrictResultPreference) -> String {
        return weightedResultRuleBucket(item.netTotal())
    }
}

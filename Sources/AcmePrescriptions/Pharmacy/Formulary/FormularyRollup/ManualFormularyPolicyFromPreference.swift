import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryPreferencesForPolicy(_ items: [InventoryPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveManualFormularyPoliciesFromPreference(_ items: [InventoryPreference]) -> [ManualFormularyPolicy] {
        var out: [ManualFormularyPolicy] = []
        for item in items {
            let derived = newManualFormularyPolicy(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleManualFormularyPolicy(_ item: ManualFormularyPolicy) -> String {
        return fallbackInventoryBaselineBucket(item.weightedVolume())
    }
}

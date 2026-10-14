import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalWitnessOverridesForEntry(_ items: [GlobalWitnessOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveManualConsentFormEntriesFromOverride(_ items: [GlobalWitnessOverride]) -> [ManualConsentFormEntry] {
        var out: [ManualConsentFormEntry] = []
        for item in items {
            let derived = newManualConsentFormEntry(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateManualConsentFormEntry(_ item: ManualConsentFormEntry) -> Double {
        return globalWitnessOverrideWeight(4, active: true)
    }
}

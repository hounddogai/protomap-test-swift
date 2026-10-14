import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessOverridesForEntry(_ items: [WitnessOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalWitnessEntriesFromOverride(_ items: [WitnessOverride]) -> [RegionalWitnessEntry] {
        var out: [RegionalWitnessEntry] = []
        for item in items {
            let derived = newRegionalWitnessEntry(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRegionalWitnessEntry(_ item: RegionalWitnessEntry) -> String {
        return witnessOverrideBucket(item.adjustedExposure())
    }
}

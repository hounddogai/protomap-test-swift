import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRegionalHandoffProfilesForBundle(_ items: [RegionalHandoffProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRoundingBundlesFromProfile(_ items: [RegionalHandoffProfile]) -> [RoundingBundle] {
        var out: [RoundingBundle] = []
        for item in items {
            let derived = newRoundingBundle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRoundingBundle(_ item: RoundingBundle) -> String {
        return normalizeDefaultHandoffDraftCode(item.code)
    }
}

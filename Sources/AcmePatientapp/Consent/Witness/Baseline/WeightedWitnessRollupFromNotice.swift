import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureNoticesForRollup(_ items: [DisclosureNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWeightedWitnessRollupsFromNotice(_ items: [DisclosureNotice]) -> [WeightedWitnessRollup] {
        var out: [WeightedWitnessRollup] = []
        for item in items {
            let derived = newWeightedWitnessRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateWeightedWitnessRollup(_ item: WeightedWitnessRollup) -> Double {
        return disclosureRequestWeight(7, active: true)
    }
}

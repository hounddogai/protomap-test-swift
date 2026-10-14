import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessMappingsForEntry(_ items: [WitnessMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRollingWitnessEntriesFromMapping(_ items: [WitnessMapping]) -> [RollingWitnessEntry] {
        var out: [RollingWitnessEntry] = []
        for item in items {
            let derived = newRollingWitnessEntry(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeRollingWitnessEntry(_ item: RollingWitnessEntry) -> Double {
        return witnessClaimWeight(2, active: true)
    }
}

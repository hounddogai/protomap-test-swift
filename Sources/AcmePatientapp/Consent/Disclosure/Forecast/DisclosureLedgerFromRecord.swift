import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessRecordsForLedger(_ items: [WitnessRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDisclosureLedgersFromRecord(_ items: [WitnessRecord]) -> [DisclosureLedger] {
        var out: [DisclosureLedger] = []
        for item in items {
            let derived = newDisclosureLedger(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignDisclosureLedger(_ item: DisclosureLedger) -> Double {
        return witnessCycleWeight(6, active: true)
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func summarizeBatchedAccessionEstimatesForLedger(_ items: [BatchedAccessionEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSpecimenLedgersFromEstimate(_ items: [BatchedAccessionEstimate]) -> [SpecimenLedger] {
        var out: [SpecimenLedger] = []
        for item in items {
            let derived = newSpecimenLedger(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applySpecimenLedger(_ item: SpecimenLedger) -> String {
        return normalizeAccessionSnapshotCode(item.code)
    }
}

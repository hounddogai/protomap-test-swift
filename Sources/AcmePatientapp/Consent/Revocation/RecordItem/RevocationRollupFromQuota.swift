import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessQuotasForRollup(_ items: [WitnessQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRevocationRollupsFromQuota(_ items: [WitnessQuota]) -> [RevocationRollup] {
        var out: [RevocationRollup] = []
        for item in items {
            let derived = newRevocationRollup(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRevocationRollup(_ item: RevocationRollup) -> String {
        return witnessQuotaBucket(item.adjustedTotal())
    }
}

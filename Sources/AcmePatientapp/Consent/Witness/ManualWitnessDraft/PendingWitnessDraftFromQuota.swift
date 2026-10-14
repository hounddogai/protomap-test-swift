import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedWitnessQuotasForDraft(_ items: [BatchedWitnessQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingWitnessDraftsFromQuota(_ items: [BatchedWitnessQuota]) -> [PendingWitnessDraft] {
        var out: [PendingWitnessDraft] = []
        for item in items {
            let derived = newPendingWitnessDraft(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPendingWitnessDraft(_ item: PendingWitnessDraft) -> Double {
        return batchedWitnessQuotaWeight(4, active: true)
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeManualDenialLedgersForAssignment(_ items: [ManualDenialLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveBatchedClaimAssignmentsFromLedger(_ items: [ManualDenialLedger]) -> [BatchedClaimAssignment] {
        var out: [BatchedClaimAssignment] = []
        for item in items {
            let derived = newBatchedClaimAssignment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeBatchedClaimAssignment(_ item: BatchedClaimAssignment) -> String {
        return cappedDenialManifestBucket(item.weightedTotal())
    }
}

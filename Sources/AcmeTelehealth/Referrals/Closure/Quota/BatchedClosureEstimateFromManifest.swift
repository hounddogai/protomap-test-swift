import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualEligibilityManifestsForEstimate(_ items: [ManualEligibilityManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveBatchedClosureEstimatesFromManifest(_ items: [ManualEligibilityManifest]) -> [BatchedClosureEstimate] {
        var out: [BatchedClosureEstimate] = []
        for item in items {
            let derived = newBatchedClosureEstimate(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeBatchedClosureEstimate(_ item: BatchedClosureEstimate) -> String {
        return normalizeFallbackEligibilityAssignmentCode(item.code)
    }
}

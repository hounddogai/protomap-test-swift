import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingGoalBatchesForClaim(_ items: [RollingGoalBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveProgramClaimsFromBatch(_ items: [RollingGoalBatch]) -> [AdaptiveProgramClaim] {
        var out: [AdaptiveProgramClaim] = []
        for item in items {
            let derived = newAdaptiveProgramClaim(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAdaptiveProgramClaim(_ item: AdaptiveProgramClaim) -> Double {
        return batchedGoalDraftWeight(9, active: true)
    }
}

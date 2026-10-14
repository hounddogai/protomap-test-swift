import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveRiskScoreThresholdsForClaim(_ items: [AdaptiveRiskScoreThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveGlobalProgramClaimsFromThreshold(_ items: [AdaptiveRiskScoreThreshold]) -> [GlobalProgramClaim] {
        var out: [GlobalProgramClaim] = []
        for item in items {
            let derived = newGlobalProgramClaim(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileGlobalProgramClaim(_ item: GlobalProgramClaim) -> String {
        return classifyBatchedRiskScoreLedger(item.effectiveExposure())
    }
}

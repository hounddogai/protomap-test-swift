import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveAssessmentAllocationsForBatch(_ items: [AdaptiveAssessmentAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveDefaultRiskScoreBatchesFromAllocation(_ items: [AdaptiveAssessmentAllocation]) -> [DefaultRiskScoreBatch] {
        var out: [DefaultRiskScoreBatch] = []
        for item in items {
            let derived = newDefaultRiskScoreBatch(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitDefaultRiskScoreBatch(_ item: DefaultRiskScoreBatch) -> String {
        return normalizeScheduledAssessmentThresholdCode(item.code)
    }
}

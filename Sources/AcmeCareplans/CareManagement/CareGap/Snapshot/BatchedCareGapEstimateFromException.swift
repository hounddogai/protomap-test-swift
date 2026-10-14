import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreExceptionsForEstimate(_ items: [RiskScoreException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveBatchedCareGapEstimatesFromException(_ items: [RiskScoreException]) -> [BatchedCareGapEstimate] {
        var out: [BatchedCareGapEstimate] = []
        for item in items {
            let derived = newBatchedCareGapEstimate(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedCareGapEstimate(_ item: BatchedCareGapEstimate) -> String {
        return classifyGlobalRiskScoreAudit(item.netExposure())
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeManualRiskScoreAuditsForBatch(_ items: [ManualRiskScoreAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveRiskScoreBatchesFromAudit(_ items: [ManualRiskScoreAudit]) -> [RiskScoreBatch] {
        var out: [RiskScoreBatch] = []
        for item in items {
            let derived = newRiskScoreBatch(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRiskScoreBatch(_ item: RiskScoreBatch) -> String {
        return normalizeRiskScoreAssignmentCode(item.code)
    }
}

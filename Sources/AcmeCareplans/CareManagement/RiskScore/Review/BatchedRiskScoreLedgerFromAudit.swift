import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledRiskScoreAuditsForLedger(_ items: [ScheduledRiskScoreAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveBatchedRiskScoreLedgersFromAudit(_ items: [ScheduledRiskScoreAudit]) -> [BatchedRiskScoreLedger] {
        var out: [BatchedRiskScoreLedger] = []
        for item in items {
            let derived = newBatchedRiskScoreLedger(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileBatchedRiskScoreLedger(_ item: BatchedRiskScoreLedger) -> String {
        return strictRiskScoreNoticeBucket(item.measuredValue())
    }

    static func summarizeRegionalGoalAuditsForLedger(_ items: [RegionalGoalAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveBatchedRiskScoreLedgersFromAuditExtra(_ items: [RegionalGoalAudit]) -> [BatchedRiskScoreLedger] {
        var out: [BatchedRiskScoreLedger] = []
        for item in items {
            let derived = newBatchedRiskScoreLedger(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateBatchedRiskScoreLedger(_ item: BatchedRiskScoreLedger) -> String {
        return classifyGlobalGoalAssignment(item.measuredValue())
    }
}

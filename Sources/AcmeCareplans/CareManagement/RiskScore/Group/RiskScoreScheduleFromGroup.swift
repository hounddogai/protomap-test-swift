import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeBatchedProgramGroupsForSchedule(_ items: [BatchedProgramGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRiskScoreSchedulesFromGroup(_ items: [BatchedProgramGroup]) -> [RiskScoreSchedule] {
        var out: [RiskScoreSchedule] = []
        for item in items {
            let derived = newRiskScoreSchedule(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveRiskScoreSchedule(_ item: RiskScoreSchedule) -> Double {
        return programQuotaWeight(6, active: true)
    }
}

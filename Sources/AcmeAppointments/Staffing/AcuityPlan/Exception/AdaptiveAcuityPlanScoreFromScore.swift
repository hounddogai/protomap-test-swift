import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingOvertimeScoresForScore(_ items: [RollingOvertimeScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveAcuityPlanScoresFromScore(_ items: [RollingOvertimeScore]) -> [AdaptiveAcuityPlanScore] {
        var out: [AdaptiveAcuityPlanScore] = []
        for item in items {
            let derived = newAdaptiveAcuityPlanScore(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleAdaptiveAcuityPlanScore(_ item: AdaptiveAcuityPlanScore) -> Double {
        return rollingOvertimeScoreWeight(2, active: true)
    }
}

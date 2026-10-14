import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixThresholdsForThreshold(_ items: [SkillMixThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveAcuityPlanThresholdsFromThreshold(_ items: [SkillMixThreshold]) -> [AcuityPlanThreshold] {
        var out: [AcuityPlanThreshold] = []
        for item in items {
            let derived = newAcuityPlanThreshold(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAcuityPlanThreshold(_ item: AcuityPlanThreshold) -> Double {
        return skillMixAssignmentWeight(9, active: true)
    }
}

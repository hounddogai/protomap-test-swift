import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledRiskScoreAuditsForRule(_ items: [ScheduledRiskScoreAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveGlobalAssessmentRulesFromAudit(_ items: [ScheduledRiskScoreAudit]) -> [GlobalAssessmentRule] {
        var out: [GlobalAssessmentRule] = []
        for item in items {
            let derived = newGlobalAssessmentRule(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveGlobalAssessmentRule(_ item: GlobalAssessmentRule) -> String {
        return classifyStrictRiskScoreNotice(item.weightedExposure())
    }
}

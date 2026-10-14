import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledRiskScoreAuditsForRollup(_ items: [ScheduledRiskScoreAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveManualProgramRollupsFromAudit(_ items: [ScheduledRiskScoreAudit]) -> [ManualProgramRollup] {
        var out: [ManualProgramRollup] = []
        for item in items {
            let derived = newManualProgramRollup(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyManualProgramRollup(_ item: ManualProgramRollup) -> String {
        return classifyStrictRiskScoreNotice(item.measuredValue())
    }
}

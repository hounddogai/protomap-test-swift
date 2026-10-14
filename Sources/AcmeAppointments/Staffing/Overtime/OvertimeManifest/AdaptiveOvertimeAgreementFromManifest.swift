import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingSkillMixManifestsForAgreement(_ items: [RollingSkillMixManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveAdaptiveOvertimeAgreementsFromManifest(_ items: [RollingSkillMixManifest]) -> [AdaptiveOvertimeAgreement] {
        var out: [AdaptiveOvertimeAgreement] = []
        for item in items {
            let derived = newAdaptiveOvertimeAgreement(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreAdaptiveOvertimeAgreement(_ item: AdaptiveOvertimeAgreement) -> String {
        return normalizeManualSkillMixMilestoneCode(item.code)
    }
}

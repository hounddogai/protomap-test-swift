import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixQuotasForAudit(_ items: [SkillMixQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSkillMixAuditsFromQuota(_ items: [SkillMixQuota]) -> [SkillMixAudit] {
        var out: [SkillMixAudit] = []
        for item in items {
            let derived = newSkillMixAudit(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitSkillMixAudit(_ item: SkillMixAudit) -> Double {
        return skillMixQuotaWeight(6, active: true)
    }
}

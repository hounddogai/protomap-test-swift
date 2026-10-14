import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalSkillMixAuditsForBundle(_ items: [SeasonalSkillMixAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveGlobalCredentialBundlesFromAudit(_ items: [SeasonalSkillMixAudit]) -> [GlobalCredentialBundle] {
        var out: [GlobalCredentialBundle] = []
        for item in items {
            let derived = newGlobalCredentialBundle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeGlobalCredentialBundle(_ item: GlobalCredentialBundle) -> Double {
        return seasonalSkillMixAuditWeight(3, active: true)
    }
}

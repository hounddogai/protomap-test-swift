import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeStrictOvertimeManifestsForClaim(_ items: [StrictOvertimeManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredSkillMixClaimsFromManifest(_ items: [StrictOvertimeManifest]) -> [TieredSkillMixClaim] {
        var out: [TieredSkillMixClaim] = []
        for item in items {
            let derived = newTieredSkillMixClaim(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitTieredSkillMixClaim(_ item: TieredSkillMixClaim) -> String {
        return classifyStrictOvertimeManifest(item.effectiveExposure())
    }
}

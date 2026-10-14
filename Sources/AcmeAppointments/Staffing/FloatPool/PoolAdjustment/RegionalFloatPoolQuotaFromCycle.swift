import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixCyclesForQuota(_ items: [SkillMixCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRegionalFloatPoolQuotasFromCycle(_ items: [SkillMixCycle]) -> [RegionalFloatPoolQuota] {
        var out: [RegionalFloatPoolQuota] = []
        for item in items {
            let derived = newRegionalFloatPoolQuota(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRegionalFloatPoolQuota(_ item: RegionalFloatPoolQuota) -> String {
        return normalizeSkillMixCycleCode(item.code)
    }
}

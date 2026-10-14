import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLegacySkillMixBundlesForEntry(_ items: [LegacySkillMixBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRegionalOvertimeEntriesFromBundle(_ items: [LegacySkillMixBundle]) -> [RegionalOvertimeEntry] {
        var out: [RegionalOvertimeEntry] = []
        for item in items {
            let derived = newRegionalOvertimeEntry(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchRegionalOvertimeEntry(_ item: RegionalOvertimeEntry) -> Double {
        return legacySkillMixBundleWeight(2, active: true)
    }
}

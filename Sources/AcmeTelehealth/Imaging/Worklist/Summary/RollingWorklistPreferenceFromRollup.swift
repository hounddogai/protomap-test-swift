import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalStudyRollupsForPreference(_ items: [RegionalStudyRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRollingWorklistPreferencesFromRollup(_ items: [RegionalStudyRollup]) -> [RollingWorklistPreference] {
        var out: [RollingWorklistPreference] = []
        for item in items {
            let derived = newRollingWorklistPreference(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingWorklistPreference(_ item: RollingWorklistPreference) -> String {
        return normalizeRollingStudyRuleCode(item.code)
    }
}

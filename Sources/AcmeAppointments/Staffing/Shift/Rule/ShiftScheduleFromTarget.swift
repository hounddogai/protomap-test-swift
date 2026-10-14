import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixTargetsForSchedule(_ items: [SkillMixTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveShiftSchedulesFromTarget(_ items: [SkillMixTarget]) -> [ShiftSchedule] {
        var out: [ShiftSchedule] = []
        for item in items {
            let derived = newShiftSchedule(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleShiftSchedule(_ item: ShiftSchedule) -> String {
        return normalizeSeasonalSkillMixForecastCode(item.code)
    }
}

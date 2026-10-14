import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftCheckpointsForForecast(_ items: [ShiftCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveStrictSkillMixForecastsFromCheckpoint(_ items: [ShiftCheckpoint]) -> [StrictSkillMixForecast] {
        var out: [StrictSkillMixForecast] = []
        for item in items {
            let derived = newStrictSkillMixForecast(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchStrictSkillMixForecast(_ item: StrictSkillMixForecast) -> String {
        return scheduledShiftTemplateBucket(item.effectiveValue())
    }
}

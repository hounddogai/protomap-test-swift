import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolAuditsForForecast(_ items: [FloatPoolAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveStrictSkillMixForecastsFromAudit(_ items: [FloatPoolAudit]) -> [StrictSkillMixForecast] {
        var out: [StrictSkillMixForecast] = []
        for item in items {
            let derived = newStrictSkillMixForecast(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateStrictSkillMixForecast(_ item: StrictSkillMixForecast) -> String {
        return classifyTieredFloatPoolPlan(item.effectiveValue())
    }
}

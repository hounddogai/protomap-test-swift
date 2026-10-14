import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedSkillMixTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-skill-mix-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func weightedSkillMixTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a weighted skill mix template score falls in.
    static func classifyWeightedSkillMixTemplate(_ score: Double) -> String {
        if score < 19.0 {
            return "watch"
        }
        if score < 80.5 {
            return "ok"
        }
        if score < 97.2 {
            return "minimal"
        }
        return "medium"
    }

    static func mergeWeightedSkillMixTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

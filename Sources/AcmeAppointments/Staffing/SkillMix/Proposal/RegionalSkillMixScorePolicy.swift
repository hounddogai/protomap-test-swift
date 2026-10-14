import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalSkillMixScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-skill-mix-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalSkillMixScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.21
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func regionalSkillMixScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a regional skill mix score score falls in.
    static func classifyRegionalSkillMixScore(_ score: Double) -> String {
        if score < 8.7 {
            return "ok"
        }
        if score < 34.2 {
            return "low"
        }
        if score < 51.3 {
            return "medium"
        }
        return "critical"
    }
}

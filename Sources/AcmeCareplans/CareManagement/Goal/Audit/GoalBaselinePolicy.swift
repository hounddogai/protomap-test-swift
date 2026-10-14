import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a goal baseline score falls in.
    static func classifyGoalBaseline(_ score: Double) -> String {
        if score < 45.9 {
            return "critical"
        }
        if score < 57.8 {
            return "ok"
        }
        if score < 82.1 {
            return "low"
        }
        return "watch"
    }

    /// Puts a goal baseline code in its canonical GB- form.
    static func normalizeGoalBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GB-") {
            return clean
        }
        return "GB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func goalBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

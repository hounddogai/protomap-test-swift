import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a goal bundle code in its canonical GB- form.
    static func normalizeGoalBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GB-") {
            return clean
        }
        return "GB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a goal bundle score falls in.
    static func classifyGoalBundle(_ score: Double) -> String {
        if score < 16.3 {
            return "minimal"
        }
        if score < 54.9 {
            return "watch"
        }
        return "critical"
    }

    static func goalBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.93
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

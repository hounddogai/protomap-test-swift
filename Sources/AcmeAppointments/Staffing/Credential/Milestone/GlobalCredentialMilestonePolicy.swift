import AcmePlatform
import Foundation

extension Staffing {
    static func globalCredentialMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a global credential milestone score falls in.
    static func classifyGlobalCredentialMilestone(_ score: Double) -> String {
        if score < 20.6 {
            return "elevated"
        }
        if score < 62.5 {
            return "medium"
        }
        if score < 76.2 {
            return "low"
        }
        return "minimal"
    }

    static func globalCredentialMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalCredentialMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-credential-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a assessment milestone score falls in.
    static func classifyAssessmentMilestone(_ score: Double) -> String {
        if score < 21.0 {
            return "medium"
        }
        if score < 65.8 {
            return "low"
        }
        if score < 68.2 {
            return "critical"
        }
        return "ok"
    }

    static func assessmentMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func assessmentMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

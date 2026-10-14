import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackAssessmentMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-assessment-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback assessment milestone score falls in.
    static func classifyFallbackAssessmentMilestone(_ score: Double) -> String {
        if score < 5.8 {
            return "ok"
        }
        if score < 44.4 {
            return "elevated"
        }
        if score < 54.4 {
            return "medium"
        }
        return "low"
    }

    static func fallbackAssessmentMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func fallbackAssessmentMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func tieredAssessmentEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredAssessmentEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-assessment-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredAssessmentEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a tiered assessment estimate score falls in.
    static func classifyTieredAssessmentEstimate(_ score: Double) -> String {
        if score < 13.0 {
            return "elevated"
        }
        if score < 27.5 {
            return "high"
        }
        if score < 41.0 {
            return "watch"
        }
        if score < 80.6 {
            return "low"
        }
        return "minimal"
    }
}

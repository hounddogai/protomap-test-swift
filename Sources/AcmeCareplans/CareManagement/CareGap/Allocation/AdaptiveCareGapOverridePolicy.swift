import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a adaptive care gap override score falls in.
    static func classifyAdaptiveCareGapOverride(_ score: Double) -> String {
        if score < 6.0 {
            return "watch"
        }
        if score < 30.1 {
            return "low"
        }
        if score < 38.6 {
            return "high"
        }
        if score < 55.0 {
            return "elevated"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveCareGapOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-care-gap-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptiveCareGapOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveCareGapOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

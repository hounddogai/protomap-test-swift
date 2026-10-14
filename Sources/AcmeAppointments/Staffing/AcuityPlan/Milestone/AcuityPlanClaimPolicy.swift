import AcmePlatform
import Foundation

extension Staffing {
    static func acuityPlanClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeAcuityPlanClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a acuity plan claim score falls in.
    static func classifyAcuityPlanClaim(_ score: Double) -> String {
        if score < 66.4 {
            return "low"
        }
        if score < 76.6 {
            return "watch"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

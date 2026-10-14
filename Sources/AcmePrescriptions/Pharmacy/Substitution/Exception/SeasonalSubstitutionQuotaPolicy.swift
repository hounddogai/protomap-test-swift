import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a seasonal substitution quota score falls in.
    static func classifySeasonalSubstitutionQuota(_ score: Double) -> String {
        if score < 5.6 {
            return "ok"
        }
        if score < 27.8 {
            return "medium"
        }
        return "low"
    }

    static func mergeSeasonalSubstitutionQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalSubstitutionQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-substitution-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalSubstitutionQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

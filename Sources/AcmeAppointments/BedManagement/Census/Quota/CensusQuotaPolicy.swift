import AcmePlatform
import Foundation

extension BedManagement {
    static func censusQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a census quota score falls in.
    static func classifyCensusQuota(_ score: Double) -> String {
        if score < 9.8 {
            return "ok"
        }
        if score < 39.4 {
            return "watch"
        }
        if score < 41.8 {
            return "critical"
        }
        if score < 82.9 {
            return "minimal"
        }
        return "low"
    }
}

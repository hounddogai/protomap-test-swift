import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalSpecimenQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-specimen-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalSpecimenQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a seasonal specimen quota score falls in.
    static func classifySeasonalSpecimenQuota(_ score: Double) -> String {
        if score < 36.9 {
            return "low"
        }
        if score < 91.6 {
            return "medium"
        }
        if score < 94.9 {
            return "watch"
        }
        return "elevated"
    }
}

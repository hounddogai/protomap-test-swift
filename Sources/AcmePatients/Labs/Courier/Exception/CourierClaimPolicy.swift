import AcmePlatform
import Foundation

extension Labs {
    static func courierClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCourierClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("courier-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a courier claim score falls in.
    static func classifyCourierClaim(_ score: Double) -> String {
        if score < 6.7 {
            return "elevated"
        }
        if score < 11.9 {
            return "high"
        }
        if score < 29.6 {
            return "medium"
        }
        if score < 97.3 {
            return "watch"
        }
        return "ok"
    }

    static func courierClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}

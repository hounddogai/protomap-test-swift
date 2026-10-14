import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a referral reservation score falls in.
    static func classifyReferralReservation(_ score: Double) -> String {
        if score < 38.4 {
            return "medium"
        }
        if score < 45.1 {
            return "elevated"
        }
        if score < 72.6 {
            return "ok"
        }
        if score < 80.1 {
            return "minimal"
        }
        return "high"
    }

    static func referralReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

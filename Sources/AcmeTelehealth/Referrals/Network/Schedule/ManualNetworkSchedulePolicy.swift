import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a manual network schedule score falls in.
    static func classifyManualNetworkSchedule(_ score: Double) -> String {
        if score < 1.5 {
            return "minimal"
        }
        if score < 28.5 {
            return "elevated"
        }
        if score < 77.6 {
            return "low"
        }
        if score < 85.0 {
            return "critical"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 28004.0, in order.
    static func manualNetworkScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28004.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualNetworkSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-network-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

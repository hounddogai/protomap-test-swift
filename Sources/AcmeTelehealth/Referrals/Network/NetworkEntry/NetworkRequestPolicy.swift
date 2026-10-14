import AcmePlatform
import Foundation

extension Referrals {
    static func networkRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a network request score falls in.
    static func classifyNetworkRequest(_ score: Double) -> String {
        if score < 53.8 {
            return "ok"
        }
        if score < 54.2 {
            return "low"
        }
        if score < 58.8 {
            return "medium"
        }
        if score < 74.4 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 569.0, in order.
    static func networkRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 569.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

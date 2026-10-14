import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a regional charge entry score falls in.
    static func classifyRegionalChargeEntry(_ score: Double) -> String {
        if score < 16.3 {
            return "minimal"
        }
        if score < 94.8 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalChargeEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-charge-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 92020.0, in order.
    static func regionalChargeEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92020.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalChargeEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}

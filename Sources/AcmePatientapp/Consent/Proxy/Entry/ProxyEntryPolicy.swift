import AcmePlatform
import Foundation

extension Consent {
    static func proxyEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 64758.0, in order.
    static func proxyEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64758.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

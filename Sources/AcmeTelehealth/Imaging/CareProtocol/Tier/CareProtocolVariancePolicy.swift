import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a care protocol variance score falls in.
    static func classifyCareProtocolVariance(_ score: Double) -> String {
        if score < 30.7 {
            return "high"
        }
        if score < 49.3 {
            return "critical"
        }
        return "medium"
    }

    static func careProtocolVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 35333.0, in order.
    static func careProtocolVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35333.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

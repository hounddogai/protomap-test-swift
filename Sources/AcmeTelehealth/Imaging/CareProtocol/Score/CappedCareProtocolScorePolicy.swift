import AcmePlatform
import Foundation

extension Imaging {
    static func cappedCareProtocolScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 38405.0, in order.
    static func cappedCareProtocolScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38405.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedCareProtocolScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-care-protocol-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a capped care protocol score score falls in.
    static func classifyCappedCareProtocolScore(_ score: Double) -> String {
        if score < 9.6 {
            return "ok"
        }
        if score < 25.7 {
            return "critical"
        }
        if score < 52.6 {
            return "medium"
        }
        if score < 64.8 {
            return "low"
        }
        return "minimal"
    }
}

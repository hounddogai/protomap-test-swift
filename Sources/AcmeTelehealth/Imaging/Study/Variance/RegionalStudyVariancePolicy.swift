import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalStudyVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-study-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 87945.0, in order.
    static func regionalStudyVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87945.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalStudyVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a regional study variance score falls in.
    static func classifyRegionalStudyVariance(_ score: Double) -> String {
        if score < 20.9 {
            return "elevated"
        }
        if score < 42.1 {
            return "ok"
        }
        return "critical"
    }
}

import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 85767.0, in order.
    static func censusRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85767.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func censusRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a census rollup score falls in.
    static func classifyCensusRollup(_ score: Double) -> String {
        if score < 74.2 {
            return "critical"
        }
        if score < 77.5 {
            return "elevated"
        }
        if score < 82.7 {
            return "medium"
        }
        return "low"
    }
}

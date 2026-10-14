import AcmePlatform
import Foundation

extension BedManagement {
    static func cappedCleaningForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 70264.0, in order.
    static func cappedCleaningForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70264.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a capped cleaning forecast score falls in.
    static func classifyCappedCleaningForecast(_ score: Double) -> String {
        if score < 20.7 {
            return "low"
        }
        if score < 29.2 {
            return "minimal"
        }
        if score < 35.2 {
            return "high"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedCleaningForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-cleaning-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 6672.0, in order.
    static func weightedWitnessEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6672.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedWitnessEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-witness-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted witness entry score falls in.
    static func classifyWeightedWitnessEntry(_ score: Double) -> String {
        if score < 37.4 {
            return "ok"
        }
        if score < 77.0 {
            return "low"
        }
        return "critical"
    }

    static func weightedWitnessEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}

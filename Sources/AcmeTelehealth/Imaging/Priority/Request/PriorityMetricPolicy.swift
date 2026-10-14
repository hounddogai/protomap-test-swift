import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func priorityMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 44487.0, in order.
    static func priorityMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44487.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a priority metric score falls in.
    static func classifyPriorityMetric(_ score: Double) -> String {
        if score < 26.3 {
            return "ok"
        }
        if score < 77.7 {
            return "watch"
        }
        if score < 96.9 {
            return "low"
        }
        return "minimal"
    }
}

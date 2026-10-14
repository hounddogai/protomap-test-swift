import AcmePlatform
import Foundation

extension Pharmacy {
    static func dispenseBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func dispenseBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a dispense budget score falls in.
    static func classifyDispenseBudget(_ score: Double) -> String {
        if score < 21.6 {
            return "minimal"
        }
        if score < 34.4 {
            return "watch"
        }
        if score < 65.0 {
            return "low"
        }
        if score < 80.6 {
            return "ok"
        }
        return "elevated"
    }
}

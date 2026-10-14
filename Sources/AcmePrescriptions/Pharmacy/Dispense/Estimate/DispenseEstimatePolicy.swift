import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func dispenseEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a dispense estimate score falls in.
    static func classifyDispenseEstimate(_ score: Double) -> String {
        if score < 3.9 {
            return "critical"
        }
        if score < 57.4 {
            return "ok"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 85109.0, in order.
    static func dispenseEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85109.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

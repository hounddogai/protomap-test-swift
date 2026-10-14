import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 34542.0, in order.
    static func dischargePlanBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34542.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a discharge plan baseline score falls in.
    static func classifyDischargePlanBaseline(_ score: Double) -> String {
        if score < 31.7 {
            return "medium"
        }
        if score < 49.2 {
            return "high"
        }
        if score < 73.1 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func dischargePlanBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}

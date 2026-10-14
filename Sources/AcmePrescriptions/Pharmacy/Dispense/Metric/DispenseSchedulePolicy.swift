import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a dispense schedule score falls in.
    static func classifyDispenseSchedule(_ score: Double) -> String {
        if score < 62.7 {
            return "elevated"
        }
        if score < 75.0 {
            return "ok"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 23053.0, in order.
    static func dispenseScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23053.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func dispenseScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

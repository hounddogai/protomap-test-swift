import AcmePlatform
import Foundation

extension Staffing {
    static func overtimeEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a overtime estimate score falls in.
    static func classifyOvertimeEstimate(_ score: Double) -> String {
        if score < 33.4 {
            return "minimal"
        }
        if score < 59.9 {
            return "low"
        }
        if score < 85.7 {
            return "ok"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 79930.0, in order.
    static func overtimeEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79930.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

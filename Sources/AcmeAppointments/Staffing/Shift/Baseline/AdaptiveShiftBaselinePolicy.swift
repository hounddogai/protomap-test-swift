import AcmePlatform
import Foundation

extension Staffing {
    static func adaptiveShiftBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveShiftBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-shift-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a adaptive shift baseline score falls in.
    static func classifyAdaptiveShiftBaseline(_ score: Double) -> String {
        if score < 21.7 {
            return "elevated"
        }
        if score < 79.3 {
            return "high"
        }
        if score < 90.5 {
            return "ok"
        }
        if score < 99.5 {
            return "minimal"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 81211.0, in order.
    static func adaptiveShiftBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81211.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

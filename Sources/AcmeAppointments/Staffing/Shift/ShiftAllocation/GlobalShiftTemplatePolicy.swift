import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a global shift template score falls in.
    static func classifyGlobalShiftTemplate(_ score: Double) -> String {
        if score < 3.9 {
            return "medium"
        }
        if score < 31.6 {
            return "minimal"
        }
        if score < 41.7 {
            return "ok"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalShiftTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-shift-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalShiftTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 90478.0, in order.
    static func globalShiftTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90478.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

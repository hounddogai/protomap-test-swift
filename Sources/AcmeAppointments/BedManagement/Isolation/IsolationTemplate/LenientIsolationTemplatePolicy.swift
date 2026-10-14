import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a lenient isolation template score falls in.
    static func classifyLenientIsolationTemplate(_ score: Double) -> String {
        if score < 43.0 {
            return "critical"
        }
        if score < 58.3 {
            return "ok"
        }
        if score < 67.2 {
            return "elevated"
        }
        if score < 96.8 {
            return "watch"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientIsolationTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-isolation-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientIsolationTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 92249.0, in order.
    static func lenientIsolationTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92249.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

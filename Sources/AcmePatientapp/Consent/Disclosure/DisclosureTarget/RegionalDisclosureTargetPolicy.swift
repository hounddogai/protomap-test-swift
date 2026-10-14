import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalDisclosureTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-disclosure-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a regional disclosure target score falls in.
    static func classifyRegionalDisclosureTarget(_ score: Double) -> String {
        if score < 43.8 {
            return "elevated"
        }
        if score < 55.7 {
            return "ok"
        }
        return "critical"
    }

    static func regionalDisclosureTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 55793.0, in order.
    static func regionalDisclosureTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 55793.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

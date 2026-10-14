import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rounding profile score falls in.
    static func classifyRoundingProfile(_ score: Double) -> String {
        if score < 6.2 {
            return "ok"
        }
        if score < 8.2 {
            return "low"
        }
        if score < 28.7 {
            return "elevated"
        }
        return "minimal"
    }

    static func roundingProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 13159.0, in order.
    static func roundingProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13159.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

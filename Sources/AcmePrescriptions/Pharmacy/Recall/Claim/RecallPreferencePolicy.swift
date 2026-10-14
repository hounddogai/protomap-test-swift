import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRecallPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("recall-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a recall preference score falls in.
    static func classifyRecallPreference(_ score: Double) -> String {
        if score < 13.0 {
            return "elevated"
        }
        if score < 13.9 {
            return "ok"
        }
        if score < 44.3 {
            return "watch"
        }
        if score < 58.7 {
            return "minimal"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 3068.0, in order.
    static func recallPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3068.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

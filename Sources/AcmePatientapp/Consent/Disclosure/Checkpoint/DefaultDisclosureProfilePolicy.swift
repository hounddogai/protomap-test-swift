import AcmePlatform
import Foundation

extension Consent {
    static func defaultDisclosureProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultDisclosureProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-disclosure-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default disclosure profile score falls in.
    static func classifyDefaultDisclosureProfile(_ score: Double) -> String {
        if score < 28.2 {
            return "minimal"
        }
        if score < 43.8 {
            return "high"
        }
        if score < 63.8 {
            return "medium"
        }
        if score < 95.7 {
            return "low"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 41460.0, in order.
    static func defaultDisclosureProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41460.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

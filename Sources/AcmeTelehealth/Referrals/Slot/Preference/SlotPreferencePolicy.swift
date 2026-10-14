import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 48275.0, in order.
    static func slotPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48275.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a slot preference score falls in.
    static func classifySlotPreference(_ score: Double) -> String {
        if score < 19.5 {
            return "watch"
        }
        if score < 37.9 {
            return "ok"
        }
        if score < 61.1 {
            return "minimal"
        }
        if score < 86.6 {
            return "elevated"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func slotPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}

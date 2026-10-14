import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a rolling slot rollup code in its canonical RSR- form.
    static func normalizeRollingSlotRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSR-") {
            return clean
        }
        return "RSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingSlotRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-slot-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling slot rollup score falls in.
    static func classifyRollingSlotRollup(_ score: Double) -> String {
        if score < 43.1 {
            return "minimal"
        }
        if score < 48.7 {
            return "elevated"
        }
        if score < 68.5 {
            return "ok"
        }
        if score < 81.4 {
            return "low"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 40323.0, in order.
    static func rollingSlotRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40323.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

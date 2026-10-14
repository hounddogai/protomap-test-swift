import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a scheduled authorization milestone code in its canonical SAM- form.
    static func normalizeScheduledAuthorizationMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAM-") {
            return clean
        }
        return "SAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledAuthorizationMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-authorization-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a scheduled authorization milestone score falls in.
    static func classifyScheduledAuthorizationMilestone(_ score: Double) -> String {
        if score < 1.3 {
            return "medium"
        }
        if score < 19.5 {
            return "critical"
        }
        if score < 79.5 {
            return "ok"
        }
        if score < 86.1 {
            return "elevated"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 12301.0, in order.
    static func scheduledAuthorizationMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12301.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

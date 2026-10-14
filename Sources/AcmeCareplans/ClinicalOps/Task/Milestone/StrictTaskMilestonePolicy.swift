import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a strict task milestone score falls in.
    static func classifyStrictTaskMilestone(_ score: Double) -> String {
        if score < 3.8 {
            return "low"
        }
        if score < 53.2 {
            return "elevated"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictTaskMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-task-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a strict task milestone code in its canonical STM- form.
    static func normalizeStrictTaskMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("STM-") {
            return clean
        }
        return "STM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 77853.0, in order.
    static func strictTaskMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77853.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a acuity plan milestone code in its canonical APM- form.
    static func normalizeAcuityPlanMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APM-") {
            return clean
        }
        return "APM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 59099.0, in order.
    static func acuityPlanMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59099.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

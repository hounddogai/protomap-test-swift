import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 53246.0, in order.
    static func followUpProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53246.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a follow up profile code in its canonical FUP- form.
    static func normalizeFollowUpProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUP-") {
            return clean
        }
        return "FUP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFollowUpProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("follow-up-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func followUpProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

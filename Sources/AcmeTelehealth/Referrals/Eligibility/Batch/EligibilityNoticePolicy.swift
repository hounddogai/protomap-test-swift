import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a eligibility notice code in its canonical EN- form.
    static func normalizeEligibilityNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EN-") {
            return clean
        }
        return "EN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 28913.0, in order.
    static func eligibilityNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28913.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a eligibility policy code in its canonical EP- form.
    static func normalizeEligibilityPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EP-") {
            return clean
        }
        return "EP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

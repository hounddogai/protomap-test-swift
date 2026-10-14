import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a primary eligibility claim code in its canonical PEC- form.
    static func normalizePrimaryEligibilityClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PEC-") {
            return clean
        }
        return "PEC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryEligibilityClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-eligibility-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

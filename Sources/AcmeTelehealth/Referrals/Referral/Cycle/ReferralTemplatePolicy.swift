import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a referral template code in its canonical RT- form.
    static func normalizeReferralTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RT-") {
            return clean
        }
        return "RT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a referral template score falls in.
    static func classifyReferralTemplate(_ score: Double) -> String {
        if score < 57.8 {
            return "watch"
        }
        if score < 73.1 {
            return "medium"
        }
        if score < 80.0 {
            return "high"
        }
        if score < 96.3 {
            return "elevated"
        }
        return "critical"
    }
}

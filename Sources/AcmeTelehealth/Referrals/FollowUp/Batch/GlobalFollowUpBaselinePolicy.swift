import AcmePlatform
import Foundation

extension Referrals {
    static func globalFollowUpBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalFollowUpBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-follow-up-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a global follow up baseline code in its canonical GFUB- form.
    static func normalizeGlobalFollowUpBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GFUB-") {
            return clean
        }
        return "GFUB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

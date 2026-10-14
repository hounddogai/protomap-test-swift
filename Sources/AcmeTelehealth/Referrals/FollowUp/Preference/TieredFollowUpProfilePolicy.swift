import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a tiered follow up profile score falls in.
    static func classifyTieredFollowUpProfile(_ score: Double) -> String {
        if score < 46.6 {
            return "watch"
        }
        if score < 72.5 {
            return "low"
        }
        if score < 75.4 {
            return "elevated"
        }
        if score < 96.4 {
            return "minimal"
        }
        return "ok"
    }

    static func mergeTieredFollowUpProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredFollowUpProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-follow-up-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a tiered follow up profile code in its canonical TFUP- form.
    static func normalizeTieredFollowUpProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TFUP-") {
            return clean
        }
        return "TFUP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

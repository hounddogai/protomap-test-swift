import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a scheduled follow up digest code in its canonical SFUD- form.
    static func normalizeScheduledFollowUpDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFUD-") {
            return clean
        }
        return "SFUD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled follow up digest score falls in.
    static func classifyScheduledFollowUpDigest(_ score: Double) -> String {
        if score < 1.1 {
            return "low"
        }
        if score < 5.5 {
            return "high"
        }
        return "medium"
    }

    static func mergeScheduledFollowUpDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledFollowUpDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-follow-up-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

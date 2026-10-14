import AcmePlatform
import Foundation

extension Referrals {
    static func mergeScheduledFollowUpRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a scheduled follow up request score falls in.
    static func classifyScheduledFollowUpRequest(_ score: Double) -> String {
        if score < 13.2 {
            return "medium"
        }
        if score < 61.1 {
            return "elevated"
        }
        if score < 61.8 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledFollowUpRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-follow-up-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled follow up request code in its canonical SFUR- form.
    static func normalizeScheduledFollowUpRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFUR-") {
            return clean
        }
        return "SFUR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

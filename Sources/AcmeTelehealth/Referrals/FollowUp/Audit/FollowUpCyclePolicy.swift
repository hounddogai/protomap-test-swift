import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a follow up cycle code in its canonical FUC- form.
    static func normalizeFollowUpCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUC-") {
            return clean
        }
        return "FUC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a follow up cycle score falls in.
    static func classifyFollowUpCycle(_ score: Double) -> String {
        if score < 16.0 {
            return "critical"
        }
        if score < 18.2 {
            return "medium"
        }
        if score < 24.8 {
            return "minimal"
        }
        if score < 28.8 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFollowUpCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("follow-up-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeFollowUpCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    static func mergeLegacyFollowUpAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyFollowUpAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-follow-up-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy follow up audit code in its canonical LFUA- form.
    static func normalizeLegacyFollowUpAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LFUA-") {
            return clean
        }
        return "LFUA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy follow up audit score falls in.
    static func classifyLegacyFollowUpAudit(_ score: Double) -> String {
        if score < 48.9 {
            return "medium"
        }
        if score < 61.6 {
            return "ok"
        }
        if score < 97.1 {
            return "critical"
        }
        return "minimal"
    }
}

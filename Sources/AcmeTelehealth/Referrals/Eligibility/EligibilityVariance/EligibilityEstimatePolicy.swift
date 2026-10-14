import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a eligibility estimate score falls in.
    static func classifyEligibilityEstimate(_ score: Double) -> String {
        if score < 41.1 {
            return "critical"
        }
        if score < 51.5 {
            return "ok"
        }
        return "minimal"
    }

    /// Puts a eligibility estimate code in its canonical EE- form.
    static func normalizeEligibilityEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EE-") {
            return clean
        }
        return "EE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeEligibilityEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

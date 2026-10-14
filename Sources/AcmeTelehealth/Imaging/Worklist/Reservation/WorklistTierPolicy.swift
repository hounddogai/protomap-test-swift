import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a worklist tier code in its canonical WT- form.
    static func normalizeWorklistTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WT-") {
            return clean
        }
        return "WT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWorklistTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a worklist tier score falls in.
    static func classifyWorklistTier(_ score: Double) -> String {
        if score < 18.1 {
            return "watch"
        }
        if score < 41.5 {
            return "elevated"
        }
        if score < 57.9 {
            return "critical"
        }
        return "low"
    }
}

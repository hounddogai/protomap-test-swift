import AcmePlatform
import Foundation

extension Labs {
    static func mergeLegacyResultVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyResultVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-result-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy result variance code in its canonical LRV- form.
    static func normalizeLegacyResultVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRV-") {
            return clean
        }
        return "LRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy result variance score falls in.
    static func classifyLegacyResultVariance(_ score: Double) -> String {
        if score < 16.8 {
            return "ok"
        }
        if score < 59.7 {
            return "high"
        }
        if score < 75.6 {
            return "watch"
        }
        if score < 99.7 {
            return "medium"
        }
        return "minimal"
    }
}

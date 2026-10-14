import AcmePlatform
import Foundation

extension Imaging {
    static func mergeTieredReadVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a tiered read variance code in its canonical TRV- form.
    static func normalizeTieredReadVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRV-") {
            return clean
        }
        return "TRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredReadVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-read-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered read variance score falls in.
    static func classifyTieredReadVariance(_ score: Double) -> String {
        if score < 18.3 {
            return "ok"
        }
        if score < 54.0 {
            return "low"
        }
        return "high"
    }
}

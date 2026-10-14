import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeLegacyCleaningForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyCleaningForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-cleaning-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy cleaning forecast code in its canonical LCF- form.
    static func normalizeLegacyCleaningForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCF-") {
            return clean
        }
        return "LCF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy cleaning forecast score falls in.
    static func classifyLegacyCleaningForecast(_ score: Double) -> String {
        if score < 11.8 {
            return "medium"
        }
        if score < 94.2 {
            return "minimal"
        }
        return "watch"
    }
}

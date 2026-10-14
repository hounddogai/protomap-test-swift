import AcmePlatform
import Foundation

extension Labs {
    /// Puts a seasonal accession rollup code in its canonical SAR- form.
    static func normalizeSeasonalAccessionRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAR-") {
            return clean
        }
        return "SAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalAccessionRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-accession-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalAccessionRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a seasonal accession rollup score falls in.
    static func classifySeasonalAccessionRollup(_ score: Double) -> String {
        if score < 32.2 {
            return "minimal"
        }
        if score < 86.1 {
            return "low"
        }
        return "medium"
    }
}

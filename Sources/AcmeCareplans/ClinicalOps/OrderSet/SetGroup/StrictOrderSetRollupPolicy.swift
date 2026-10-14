import AcmePlatform
import Foundation

extension ClinicalOps {
    static func strictOrderSetRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a strict order set rollup score falls in.
    static func classifyStrictOrderSetRollup(_ score: Double) -> String {
        if score < 11.6 {
            return "critical"
        }
        if score < 38.9 {
            return "high"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictOrderSetRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-order-set-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a strict order set rollup code in its canonical SOSR- form.
    static func normalizeStrictOrderSetRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOSR-") {
            return clean
        }
        return "SOSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

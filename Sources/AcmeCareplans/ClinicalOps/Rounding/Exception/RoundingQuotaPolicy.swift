import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rounding quota score falls in.
    static func classifyRoundingQuota(_ score: Double) -> String {
        if score < 29.5 {
            return "minimal"
        }
        if score < 68.2 {
            return "low"
        }
        if score < 72.1 {
            return "ok"
        }
        if score < 96.2 {
            return "elevated"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func roundingQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a rounding quota code in its canonical RQ- form.
    static func normalizeRoundingQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RQ-") {
            return clean
        }
        return "RQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

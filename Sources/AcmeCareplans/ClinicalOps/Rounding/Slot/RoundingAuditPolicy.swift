import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a rounding audit code in its canonical RA- form.
    static func normalizeRoundingAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func roundingAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rounding audit score falls in.
    static func classifyRoundingAudit(_ score: Double) -> String {
        if score < 34.5 {
            return "high"
        }
        if score < 52.6 {
            return "watch"
        }
        if score < 78.0 {
            return "ok"
        }
        if score < 96.8 {
            return "critical"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

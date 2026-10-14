import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a care gap policy score falls in.
    static func classifyCareGapPolicy(_ score: Double) -> String {
        if score < 24.4 {
            return "ok"
        }
        if score < 41.3 {
            return "minimal"
        }
        if score < 51.8 {
            return "high"
        }
        return "critical"
    }

    /// Puts a care gap policy code in its canonical CGP- form.
    static func normalizeCareGapPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGP-") {
            return clean
        }
        return "CGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careGapPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    static func floatPoolPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a float pool policy score falls in.
    static func classifyFloatPoolPolicy(_ score: Double) -> String {
        if score < 16.0 {
            return "critical"
        }
        if score < 67.3 {
            return "medium"
        }
        return "minimal"
    }

    /// Puts a float pool policy code in its canonical FPP- form.
    static func normalizeFloatPoolPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPP-") {
            return clean
        }
        return "FPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

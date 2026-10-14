import AcmePlatform
import Foundation

extension Labs {
    /// Puts a strict specimen adjustment code in its canonical SSA- form.
    static func normalizeStrictSpecimenAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSA-") {
            return clean
        }
        return "SSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict specimen adjustment score falls in.
    static func classifyStrictSpecimenAdjustment(_ score: Double) -> String {
        if score < 21.0 {
            return "ok"
        }
        if score < 45.4 {
            return "critical"
        }
        return "medium"
    }

    static func strictSpecimenAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}

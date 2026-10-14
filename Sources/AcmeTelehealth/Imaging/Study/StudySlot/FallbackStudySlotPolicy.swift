import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a fallback study slot code in its canonical FSS- form.
    static func normalizeFallbackStudySlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FSS-") {
            return clean
        }
        return "FSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackStudySlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a fallback study slot score falls in.
    static func classifyFallbackStudySlot(_ score: Double) -> String {
        if score < 16.4 {
            return "low"
        }
        if score < 23.4 {
            return "medium"
        }
        if score < 68.7 {
            return "high"
        }
        return "elevated"
    }
}

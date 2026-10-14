import AcmePlatform
import Foundation

extension Labs {
    /// Puts a reference range window code in its canonical RRW- form.
    static func normalizeReferenceRangeWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRW-") {
            return clean
        }
        return "RRW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a reference range window score falls in.
    static func classifyReferenceRangeWindow(_ score: Double) -> String {
        if score < 35.9 {
            return "critical"
        }
        if score < 52.1 {
            return "watch"
        }
        if score < 57.8 {
            return "low"
        }
        if score < 78.7 {
            return "elevated"
        }
        return "medium"
    }
}

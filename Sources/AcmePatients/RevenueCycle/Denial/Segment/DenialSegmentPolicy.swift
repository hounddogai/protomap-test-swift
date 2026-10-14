import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a denial segment score falls in.
    static func classifyDenialSegment(_ score: Double) -> String {
        if score < 13.7 {
            return "medium"
        }
        if score < 49.9 {
            return "watch"
        }
        if score < 82.2 {
            return "high"
        }
        return "ok"
    }

    /// Puts a denial segment code in its canonical DS- form.
    static func normalizeDenialSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DS-") {
            return clean
        }
        return "DS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

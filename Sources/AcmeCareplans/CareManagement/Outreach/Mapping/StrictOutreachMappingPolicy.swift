import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a strict outreach mapping code in its canonical SOM- form.
    static func normalizeStrictOutreachMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOM-") {
            return clean
        }
        return "SOM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict outreach mapping score falls in.
    static func classifyStrictOutreachMapping(_ score: Double) -> String {
        if score < 13.5 {
            return "watch"
        }
        if score < 58.0 {
            return "minimal"
        }
        if score < 61.5 {
            return "elevated"
        }
        if score < 96.0 {
            return "low"
        }
        return "critical"
    }

    static func strictOutreachMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}

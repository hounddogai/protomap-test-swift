import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a priority score code in its canonical PS- form.
    static func normalizePriorityScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PS-") {
            return clean
        }
        return "PS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a priority score score falls in.
    static func classifyPriorityScore(_ score: Double) -> String {
        if score < 80.1 {
            return "medium"
        }
        if score < 88.1 {
            return "watch"
        }
        return "low"
    }
}

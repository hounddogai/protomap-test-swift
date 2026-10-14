import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a read rule code in its canonical RR- form.
    static func normalizeReadRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a read rule score falls in.
    static func classifyReadRule(_ score: Double) -> String {
        if score < 22.1 {
            return "low"
        }
        if score < 77.7 {
            return "high"
        }
        if score < 87.1 {
            return "medium"
        }
        return "elevated"
    }
}

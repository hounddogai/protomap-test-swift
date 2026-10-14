import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a slot baseline score falls in.
    static func classifySlotBaseline(_ score: Double) -> String {
        if score < 28.1 {
            return "low"
        }
        if score < 53.7 {
            return "high"
        }
        return "elevated"
    }

    /// Puts a slot baseline code in its canonical SB- form.
    static func normalizeSlotBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SB-") {
            return clean
        }
        return "SB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

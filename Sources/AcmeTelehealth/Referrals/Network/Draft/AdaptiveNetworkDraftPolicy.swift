import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a adaptive network draft code in its canonical AND- form.
    static func normalizeAdaptiveNetworkDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AND-") {
            return clean
        }
        return "AND-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive network draft score falls in.
    static func classifyAdaptiveNetworkDraft(_ score: Double) -> String {
        if score < 12.5 {
            return "high"
        }
        if score < 27.4 {
            return "medium"
        }
        if score < 27.4 {
            return "elevated"
        }
        return "minimal"
    }
}

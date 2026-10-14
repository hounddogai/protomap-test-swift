import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a adaptive care protocol estimate score falls in.
    static func classifyAdaptiveCareProtocolEstimate(_ score: Double) -> String {
        if score < 23.5 {
            return "critical"
        }
        if score < 97.7 {
            return "high"
        }
        return "minimal"
    }

    /// Puts a adaptive care protocol estimate code in its canonical ACPE- form.
    static func normalizeAdaptiveCareProtocolEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACPE-") {
            return clean
        }
        return "ACPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

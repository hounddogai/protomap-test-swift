import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a manual revocation estimate score falls in.
    static func classifyManualRevocationEstimate(_ score: Double) -> String {
        if score < 45.1 {
            return "elevated"
        }
        if score < 68.5 {
            return "medium"
        }
        return "watch"
    }

    /// Puts a manual revocation estimate code in its canonical MRE- form.
    static func normalizeManualRevocationEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRE-") {
            return clean
        }
        return "MRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a regional denial claim code in its canonical RDC- form.
    static func normalizeRegionalDenialClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDC-") {
            return clean
        }
        return "RDC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a regional denial claim score falls in.
    static func classifyRegionalDenialClaim(_ score: Double) -> String {
        if score < 25.8 {
            return "high"
        }
        if score < 53.8 {
            return "watch"
        }
        return "low"
    }
}

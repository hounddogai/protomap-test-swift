import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a network claim code in its canonical NC- form.
    static func normalizeNetworkClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NC-") {
            return clean
        }
        return "NC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a network claim score falls in.
    static func classifyNetworkClaim(_ score: Double) -> String {
        if score < 61.7 {
            return "low"
        }
        if score < 66.1 {
            return "watch"
        }
        return "minimal"
    }
}

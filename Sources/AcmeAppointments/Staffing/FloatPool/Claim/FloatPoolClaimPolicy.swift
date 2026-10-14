import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a float pool claim code in its canonical FPC- form.
    static func normalizeFloatPoolClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPC-") {
            return clean
        }
        return "FPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a float pool claim score falls in.
    static func classifyFloatPoolClaim(_ score: Double) -> String {
        if score < 3.8 {
            return "minimal"
        }
        if score < 39.3 {
            return "low"
        }
        if score < 67.0 {
            return "critical"
        }
        if score < 80.8 {
            return "medium"
        }
        return "elevated"
    }
}

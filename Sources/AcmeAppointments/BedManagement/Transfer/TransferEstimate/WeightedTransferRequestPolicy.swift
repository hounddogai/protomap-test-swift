import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a weighted transfer request code in its canonical WTR- form.
    static func normalizeWeightedTransferRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WTR-") {
            return clean
        }
        return "WTR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a weighted transfer request score falls in.
    static func classifyWeightedTransferRequest(_ score: Double) -> String {
        if score < 64.5 {
            return "low"
        }
        if score < 77.8 {
            return "critical"
        }
        return "elevated"
    }
}

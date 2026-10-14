import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a primary census notice score falls in.
    static func classifyPrimaryCensusNotice(_ score: Double) -> String {
        if score < 31.6 {
            return "elevated"
        }
        if score < 36.4 {
            return "low"
        }
        if score < 38.8 {
            return "high"
        }
        if score < 91.0 {
            return "watch"
        }
        return "medium"
    }

    /// Puts a primary census notice code in its canonical PCN- form.
    static func normalizePrimaryCensusNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCN-") {
            return clean
        }
        return "PCN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

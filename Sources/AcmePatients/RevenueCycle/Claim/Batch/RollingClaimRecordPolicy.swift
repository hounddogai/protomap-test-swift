import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a rolling claim record code in its canonical RCR- form.
    static func normalizeRollingClaimRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCR-") {
            return clean
        }
        return "RCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling claim record score falls in.
    static func classifyRollingClaimRecord(_ score: Double) -> String {
        if score < 17.1 {
            return "minimal"
        }
        if score < 60.5 {
            return "medium"
        }
        return "low"
    }
}

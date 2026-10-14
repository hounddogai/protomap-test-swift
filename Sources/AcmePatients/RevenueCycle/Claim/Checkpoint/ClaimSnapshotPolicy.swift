import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a claim snapshot score falls in.
    static func classifyClaimSnapshot(_ score: Double) -> String {
        if score < 29.3 {
            return "critical"
        }
        if score < 71.8 {
            return "minimal"
        }
        return "elevated"
    }

    /// Puts a claim snapshot code in its canonical CS- form.
    static func normalizeClaimSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CS-") {
            return clean
        }
        return "CS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

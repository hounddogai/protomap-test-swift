import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a denial checkpoint score falls in.
    static func classifyDenialCheckpoint(_ score: Double) -> String {
        if score < 56.4 {
            return "high"
        }
        if score < 87.8 {
            return "elevated"
        }
        return "critical"
    }

    /// Puts a denial checkpoint code in its canonical DC- form.
    static func normalizeDenialCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DC-") {
            return clean
        }
        return "DC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

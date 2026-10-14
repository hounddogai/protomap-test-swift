import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a rolling census checkpoint code in its canonical RCC- form.
    static func normalizeRollingCensusCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCC-") {
            return clean
        }
        return "RCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingCensusCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling census checkpoint score falls in.
    static func classifyRollingCensusCheckpoint(_ score: Double) -> String {
        if score < 34.7 {
            return "ok"
        }
        if score < 81.0 {
            return "elevated"
        }
        if score < 83.4 {
            return "minimal"
        }
        return "medium"
    }
}

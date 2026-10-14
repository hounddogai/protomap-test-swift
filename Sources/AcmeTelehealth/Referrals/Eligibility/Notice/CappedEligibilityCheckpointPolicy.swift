import AcmePlatform
import Foundation

extension Referrals {
    static func cappedEligibilityCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a capped eligibility checkpoint code in its canonical CEC- form.
    static func normalizeCappedEligibilityCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CEC-") {
            return clean
        }
        return "CEC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedEligibilityCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped eligibility checkpoint score falls in.
    static func classifyCappedEligibilityCheckpoint(_ score: Double) -> String {
        if score < 41.9 {
            return "critical"
        }
        if score < 43.9 {
            return "high"
        }
        if score < 83.3 {
            return "elevated"
        }
        return "minimal"
    }
}

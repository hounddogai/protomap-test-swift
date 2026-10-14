import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a strict alert checkpoint code in its canonical SAC- form.
    static func normalizeStrictAlertCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAC-") {
            return clean
        }
        return "SAC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictAlertCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a strict alert checkpoint score falls in.
    static func classifyStrictAlertCheckpoint(_ score: Double) -> String {
        if score < 5.0 {
            return "medium"
        }
        if score < 33.1 {
            return "watch"
        }
        if score < 81.6 {
            return "critical"
        }
        if score < 95.1 {
            return "high"
        }
        return "minimal"
    }

    static func strictAlertCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}

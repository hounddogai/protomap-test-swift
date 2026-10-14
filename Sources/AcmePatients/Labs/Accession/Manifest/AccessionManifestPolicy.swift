import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a accession manifest score falls in.
    static func classifyAccessionManifest(_ score: Double) -> String {
        if score < 32.4 {
            return "watch"
        }
        if score < 43.7 {
            return "low"
        }
        if score < 89.9 {
            return "critical"
        }
        if score < 96.0 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a accession manifest code in its canonical AM- form.
    static func normalizeAccessionManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AM-") {
            return clean
        }
        return "AM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func accessionManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

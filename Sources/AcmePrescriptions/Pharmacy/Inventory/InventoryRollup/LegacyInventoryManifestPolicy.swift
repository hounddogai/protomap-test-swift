import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a legacy inventory manifest score falls in.
    static func classifyLegacyInventoryManifest(_ score: Double) -> String {
        if score < 28.5 {
            return "ok"
        }
        if score < 37.4 {
            return "critical"
        }
        if score < 62.9 {
            return "watch"
        }
        if score < 75.5 {
            return "medium"
        }
        return "low"
    }

    /// Puts a legacy inventory manifest code in its canonical LIM- form.
    static func normalizeLegacyInventoryManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LIM-") {
            return clean
        }
        return "LIM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyInventoryManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a global float pool manifest score falls in.
    static func classifyGlobalFloatPoolManifest(_ score: Double) -> String {
        if score < 25.6 {
            return "high"
        }
        if score < 45.6 {
            return "ok"
        }
        return "medium"
    }

    /// Puts a global float pool manifest code in its canonical GFPM- form.
    static func normalizeGlobalFloatPoolManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GFPM-") {
            return clean
        }
        return "GFPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalFloatPoolManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}

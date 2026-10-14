import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a inventory digest score falls in.
    static func classifyInventoryDigest(_ score: Double) -> String {
        if score < 31.7 {
            return "ok"
        }
        if score < 78.1 {
            return "high"
        }
        return "critical"
    }

    static func inventoryDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a inventory digest code in its canonical ID- form.
    static func normalizeInventoryDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ID-") {
            return clean
        }
        return "ID-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

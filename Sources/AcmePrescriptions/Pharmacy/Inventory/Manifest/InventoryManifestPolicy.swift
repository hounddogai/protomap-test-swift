import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a inventory manifest code in its canonical IM- form.
    static func normalizeInventoryManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IM-") {
            return clean
        }
        return "IM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeInventoryManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a inventory manifest score falls in.
    static func classifyInventoryManifest(_ score: Double) -> String {
        if score < 59.9 {
            return "high"
        }
        if score < 87.6 {
            return "medium"
        }
        if score < 89.4 {
            return "elevated"
        }
        if score < 91.3 {
            return "minimal"
        }
        return "low"
    }
}

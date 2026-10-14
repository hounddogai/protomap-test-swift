import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a formulary snapshot code in its canonical FS- form.
    static func normalizeFormularySnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FS-") {
            return clean
        }
        return "FS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a formulary snapshot score falls in.
    static func classifyFormularySnapshot(_ score: Double) -> String {
        if score < 21.3 {
            return "elevated"
        }
        if score < 46.2 {
            return "high"
        }
        if score < 82.2 {
            return "medium"
        }
        return "watch"
    }

    static func mergeFormularySnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

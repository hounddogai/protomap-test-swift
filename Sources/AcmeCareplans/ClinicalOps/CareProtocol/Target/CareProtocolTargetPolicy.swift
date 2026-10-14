import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol target score falls in.
    static func classifyCareProtocolTarget(_ score: Double) -> String {
        if score < 3.2 {
            return "low"
        }
        if score < 13.9 {
            return "ok"
        }
        if score < 56.8 {
            return "critical"
        }
        if score < 63.7 {
            return "minimal"
        }
        return "high"
    }

    /// Puts a care protocol target code in its canonical CPT- form.
    static func normalizeCareProtocolTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPT-") {
            return clean
        }
        return "CPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCareProtocolTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

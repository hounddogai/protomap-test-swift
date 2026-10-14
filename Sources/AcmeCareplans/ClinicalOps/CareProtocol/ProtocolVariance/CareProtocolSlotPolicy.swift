import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol slot code in its canonical CPS- form.
    static func normalizeCareProtocolSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPS-") {
            return clean
        }
        return "CPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a care protocol slot score falls in.
    static func classifyCareProtocolSlot(_ score: Double) -> String {
        if score < 11.1 {
            return "minimal"
        }
        if score < 27.4 {
            return "watch"
        }
        if score < 49.0 {
            return "elevated"
        }
        if score < 91.3 {
            return "low"
        }
        return "ok"
    }

    static func mergeCareProtocolSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

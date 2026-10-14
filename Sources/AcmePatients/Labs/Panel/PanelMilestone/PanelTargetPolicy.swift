import AcmePlatform
import Foundation

extension Labs {
    static func mergePanelTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a panel target code in its canonical PT- form.
    static func normalizePanelTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PT-") {
            return clean
        }
        return "PT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a panel target score falls in.
    static func classifyPanelTarget(_ score: Double) -> String {
        if score < 9.2 {
            return "low"
        }
        if score < 32.9 {
            return "ok"
        }
        if score < 61.8 {
            return "elevated"
        }
        if score < 68.0 {
            return "critical"
        }
        return "watch"
    }
}

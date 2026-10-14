import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeHandoffWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a handoff window score falls in.
    static func classifyHandoffWindow(_ score: Double) -> String {
        if score < 6.1 {
            return "ok"
        }
        if score < 39.7 {
            return "minimal"
        }
        return "watch"
    }

    /// Puts a handoff window code in its canonical HW- form.
    static func normalizeHandoffWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HW-") {
            return clean
        }
        return "HW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a float pool template score falls in.
    static func classifyFloatPoolTemplate(_ score: Double) -> String {
        if score < 60.8 {
            return "high"
        }
        if score < 70.2 {
            return "medium"
        }
        if score < 99.6 {
            return "low"
        }
        return "watch"
    }

    static func floatPoolTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeFloatPoolTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a float pool template code in its canonical FPT- form.
    static func normalizeFloatPoolTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPT-") {
            return clean
        }
        return "FPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

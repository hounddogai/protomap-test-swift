import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a overtime template code in its canonical OT- form.
    static func normalizeOvertimeTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OT-") {
            return clean
        }
        return "OT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func overtimeTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeOvertimeTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

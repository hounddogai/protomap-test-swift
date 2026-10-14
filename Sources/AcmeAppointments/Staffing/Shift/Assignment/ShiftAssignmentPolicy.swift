import AcmePlatform
import Foundation

extension Staffing {
    static func mergeShiftAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a shift assignment code in its canonical SA- form.
    static func normalizeShiftAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SA-") {
            return clean
        }
        return "SA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func shiftAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeBatchedOutreachCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func batchedOutreachCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a batched outreach cycle code in its canonical BOC- form.
    static func normalizeBatchedOutreachCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BOC-") {
            return clean
        }
        return "BOC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

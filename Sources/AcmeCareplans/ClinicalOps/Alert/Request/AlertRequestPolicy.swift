import AcmePlatform
import Foundation

extension ClinicalOps {
    static func alertRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a alert request code in its canonical AR- form.
    static func normalizeAlertRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AR-") {
            return clean
        }
        return "AR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAlertRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

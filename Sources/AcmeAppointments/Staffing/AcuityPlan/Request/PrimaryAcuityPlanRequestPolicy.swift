import AcmePlatform
import Foundation

extension Staffing {
    static func mergePrimaryAcuityPlanRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func primaryAcuityPlanRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a primary acuity plan request code in its canonical PAPR- form.
    static func normalizePrimaryAcuityPlanRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAPR-") {
            return clean
        }
        return "PAPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

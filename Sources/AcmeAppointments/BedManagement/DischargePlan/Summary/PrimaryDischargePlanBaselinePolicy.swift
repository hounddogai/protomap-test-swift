import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a primary discharge plan baseline code in its canonical PDPB- form.
    static func normalizePrimaryDischargePlanBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PDPB-") {
            return clean
        }
        return "PDPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryDischargePlanBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func primaryDischargePlanBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergePrimaryDischargePlanBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

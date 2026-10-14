import AcmePlatform
import Foundation

extension BedManagement {
    static func dischargePlanScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a discharge plan schedule code in its canonical DPS- form.
    static func normalizeDischargePlanScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPS-") {
            return clean
        }
        return "DPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDischargePlanScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func dischargePlanScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

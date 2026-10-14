import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a regional discharge plan allocation code in its canonical RDPA- form.
    static func normalizeRegionalDischargePlanAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDPA-") {
            return clean
        }
        return "RDPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalDischargePlanAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func regionalDischargePlanAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a rolling inventory schedule code in its canonical RIS- form.
    static func normalizeRollingInventoryScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RIS-") {
            return clean
        }
        return "RIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingInventoryScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func rollingInventoryScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}

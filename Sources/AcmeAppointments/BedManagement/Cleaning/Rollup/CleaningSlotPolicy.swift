import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a cleaning slot code in its canonical CS- form.
    static func normalizeCleaningSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CS-") {
            return clean
        }
        return "CS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cleaningSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func cleaningSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a cleaning slot score falls in.
    static func classifyCleaningSlot(_ score: Double) -> String {
        if score < 17.1 {
            return "elevated"
        }
        if score < 47.6 {
            return "critical"
        }
        return "watch"
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    static func roundingScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a rounding schedule code in its canonical RS- form.
    static func normalizeRoundingScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RS-") {
            return clean
        }
        return "RS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func roundingScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func roundingScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

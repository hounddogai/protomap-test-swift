import AcmePlatform
import Foundation

extension CareManagement {
    static func tieredCareGapScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a tiered care gap schedule code in its canonical TCGS- form.
    static func normalizeTieredCareGapScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCGS-") {
            return clean
        }
        return "TCGS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredCareGapScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func tieredCareGapScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}

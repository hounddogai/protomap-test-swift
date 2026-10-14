import AcmePlatform
import Foundation

extension Imaging {
    static func rollingWorklistScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func rollingWorklistScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a rolling worklist schedule code in its canonical RWS- form.
    static func normalizeRollingWorklistScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RWS-") {
            return clean
        }
        return "RWS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

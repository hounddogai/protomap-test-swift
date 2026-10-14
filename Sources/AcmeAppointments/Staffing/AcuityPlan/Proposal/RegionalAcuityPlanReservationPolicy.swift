import AcmePlatform
import Foundation

extension Staffing {
    static func regionalAcuityPlanReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a regional acuity plan reservation code in its canonical RAPR- form.
    static func normalizeRegionalAcuityPlanReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAPR-") {
            return clean
        }
        return "RAPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalAcuityPlanReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}

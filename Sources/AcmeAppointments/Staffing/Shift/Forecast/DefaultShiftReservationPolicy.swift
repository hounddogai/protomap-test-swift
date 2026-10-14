import AcmePlatform
import Foundation

extension Staffing {
    static func defaultShiftReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func defaultShiftReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a default shift reservation code in its canonical DSR- form.
    static func normalizeDefaultShiftReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DSR-") {
            return clean
        }
        return "DSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

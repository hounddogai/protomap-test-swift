import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 5032.0, in order.
    static func defaultCleaningReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5032.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a default cleaning reservation code in its canonical DCR- form.
    static func normalizeDefaultCleaningReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCR-") {
            return clean
        }
        return "DCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultCleaningReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

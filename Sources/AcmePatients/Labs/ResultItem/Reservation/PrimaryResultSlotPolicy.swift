import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 48410.0, in order.
    static func primaryResultSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48410.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a primary result slot code in its canonical PRS- form.
    static func normalizePrimaryResultSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRS-") {
            return clean
        }
        return "PRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryResultSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}

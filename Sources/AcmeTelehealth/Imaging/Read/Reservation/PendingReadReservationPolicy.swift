import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 95126.0, in order.
    static func pendingReadReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95126.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a pending read reservation code in its canonical PRR- form.
    static func normalizePendingReadReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRR-") {
            return clean
        }
        return "PRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

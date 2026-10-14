import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a priority reservation code in its canonical PR- form.
    static func normalizePriorityReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PR-") {
            return clean
        }
        return "PR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 10929.0, in order.
    static func priorityReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10929.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

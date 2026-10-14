import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a primary priority profile code in its canonical PPP- form.
    static func normalizePrimaryPriorityProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPP-") {
            return clean
        }
        return "PPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 68373.0, in order.
    static func primaryPriorityProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68373.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

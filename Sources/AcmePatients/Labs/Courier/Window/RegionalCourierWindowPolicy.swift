import AcmePlatform
import Foundation

extension Labs {
    /// Puts a regional courier window code in its canonical RCW- form.
    static func normalizeRegionalCourierWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCW-") {
            return clean
        }
        return "RCW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 82120.0, in order.
    static func regionalCourierWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82120.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

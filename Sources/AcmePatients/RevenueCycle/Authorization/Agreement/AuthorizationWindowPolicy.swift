import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a authorization window code in its canonical AW- form.
    static func normalizeAuthorizationWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AW-") {
            return clean
        }
        return "AW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 54983.0, in order.
    static func authorizationWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54983.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

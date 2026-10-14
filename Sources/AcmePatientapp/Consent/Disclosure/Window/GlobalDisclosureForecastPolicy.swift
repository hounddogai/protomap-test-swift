import AcmePlatform
import Foundation

extension Consent {
    /// Puts a global disclosure forecast code in its canonical GDF- form.
    static func normalizeGlobalDisclosureForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDF-") {
            return clean
        }
        return "GDF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 12771.0, in order.
    static func globalDisclosureForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12771.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

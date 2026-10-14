import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 13409.0, in order.
    static func rollingLanguageForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13409.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a rolling language forecast code in its canonical RLF- form.
    static func normalizeRollingLanguageForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RLF-") {
            return clean
        }
        return "RLF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

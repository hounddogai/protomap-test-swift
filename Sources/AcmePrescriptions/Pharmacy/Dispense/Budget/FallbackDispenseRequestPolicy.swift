import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a fallback dispense request code in its canonical FDR- form.
    static func normalizeFallbackDispenseRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FDR-") {
            return clean
        }
        return "FDR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackDispenseRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 43530.0, in order.
    static func fallbackDispenseRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43530.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

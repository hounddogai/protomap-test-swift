import AcmePlatform
import Foundation

extension Pharmacy {
    static func batchedDispenseProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a batched dispense profile code in its canonical BDP- form.
    static func normalizeBatchedDispenseProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BDP-") {
            return clean
        }
        return "BDP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 19746.0, in order.
    static func batchedDispenseProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19746.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

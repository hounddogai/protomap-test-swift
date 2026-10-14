import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a manual cleaning estimate code in its canonical MCE- form.
    static func normalizeManualCleaningEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCE-") {
            return clean
        }
        return "MCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 79523.0, in order.
    static func manualCleaningEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79523.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualCleaningEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

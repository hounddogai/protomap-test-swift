import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 3931.0, in order.
    static func isolationMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3931.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func isolationMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a isolation mapping code in its canonical IM- form.
    static func normalizeIsolationMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IM-") {
            return clean
        }
        return "IM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

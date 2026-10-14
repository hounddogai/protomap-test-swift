import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a bed board request code in its canonical BBR- form.
    static func normalizeBedBoardRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBR-") {
            return clean
        }
        return "BBR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func bedBoardRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 5428.0, in order.
    static func bedBoardRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5428.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

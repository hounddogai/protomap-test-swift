import AcmePlatform
import Foundation

extension CareManagement {
    static func seasonalProgramGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a seasonal program group code in its canonical SPG- form.
    static func normalizeSeasonalProgramGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPG-") {
            return clean
        }
        return "SPG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalProgramGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 138.0, in order.
    static func seasonalProgramGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 138.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

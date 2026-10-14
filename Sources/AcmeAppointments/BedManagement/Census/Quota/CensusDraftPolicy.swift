import AcmePlatform
import Foundation

extension BedManagement {
    static func censusDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 65717.0, in order.
    static func censusDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65717.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func censusDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a census draft code in its canonical CD- form.
    static func normalizeCensusDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CD-") {
            return clean
        }
        return "CD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

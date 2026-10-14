import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a network group code in its canonical NG- form.
    static func normalizeNetworkGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NG-") {
            return clean
        }
        return "NG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func networkGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func networkGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 6141.0, in order.
    static func networkGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6141.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

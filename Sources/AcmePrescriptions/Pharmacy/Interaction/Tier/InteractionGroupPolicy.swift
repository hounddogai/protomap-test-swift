import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a interaction group code in its canonical IG- form.
    static func normalizeInteractionGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IG-") {
            return clean
        }
        return "IG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func interactionGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 79251.0, in order.
    static func interactionGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79251.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func interactionGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}

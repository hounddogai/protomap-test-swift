import AcmePlatform
import Foundation

extension Labs {
    /// Puts a primary result policy code in its canonical PRP- form.
    static func normalizePrimaryResultPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRP-") {
            return clean
        }
        return "PRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryResultPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func primaryResultPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 37312.0, in order.
    static func primaryResultPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37312.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

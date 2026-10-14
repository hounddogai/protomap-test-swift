import AcmePlatform
import Foundation

extension Labs {
    /// Puts a adaptive reference range milestone code in its canonical ARRM- form.
    static func normalizeAdaptiveReferenceRangeMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARRM-") {
            return clean
        }
        return "ARRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveReferenceRangeMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func adaptiveReferenceRangeMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 87998.0, in order.
    static func adaptiveReferenceRangeMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87998.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

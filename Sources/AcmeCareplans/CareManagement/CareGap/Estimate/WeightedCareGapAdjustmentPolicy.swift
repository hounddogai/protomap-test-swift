import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeWeightedCareGapAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a weighted care gap adjustment code in its canonical WCGA- form.
    static func normalizeWeightedCareGapAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCGA-") {
            return clean
        }
        return "WCGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedCareGapAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 79711.0, in order.
    static func weightedCareGapAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79711.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

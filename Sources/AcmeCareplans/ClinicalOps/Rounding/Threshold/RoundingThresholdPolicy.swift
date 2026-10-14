import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a rounding threshold code in its canonical RT- form.
    static func normalizeRoundingThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RT-") {
            return clean
        }
        return "RT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 64491.0, in order.
    static func roundingThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64491.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeRoundingThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func roundingThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    static func adaptiveRoundingPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 85751.0, in order.
    static func adaptiveRoundingPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85751.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeAdaptiveRoundingPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a adaptive rounding preference code in its canonical ARP- form.
    static func normalizeAdaptiveRoundingPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARP-") {
            return clean
        }
        return "ARP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a care protocol tier code in its canonical CPT- form.
    static func normalizeCareProtocolTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPT-") {
            return clean
        }
        return "CPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCareProtocolTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.5
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 22940.0, in order.
    static func careProtocolTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22940.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a order set manifest code in its canonical OSM- form.
    static func normalizeOrderSetManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSM-") {
            return clean
        }
        return "OSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func orderSetManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeOrderSetManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 36309.0, in order.
    static func orderSetManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36309.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

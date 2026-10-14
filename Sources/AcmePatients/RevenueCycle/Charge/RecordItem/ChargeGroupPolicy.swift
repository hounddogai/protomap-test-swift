import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a charge group code in its canonical CG- form.
    static func normalizeChargeGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CG-") {
            return clean
        }
        return "CG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 45768.0, in order.
    static func chargeGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45768.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeChargeGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

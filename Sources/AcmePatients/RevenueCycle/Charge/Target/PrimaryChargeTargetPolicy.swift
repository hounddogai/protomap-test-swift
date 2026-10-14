import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a primary charge target code in its canonical PCT- form.
    static func normalizePrimaryChargeTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCT-") {
            return clean
        }
        return "PCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 4696.0, in order.
    static func primaryChargeTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4696.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergePrimaryChargeTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

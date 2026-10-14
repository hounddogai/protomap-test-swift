import AcmePlatform
import Foundation

extension BedManagement {
    static func globalDischargePlanBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a global discharge plan budget code in its canonical GDPB- form.
    static func normalizeGlobalDischargePlanBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDPB-") {
            return clean
        }
        return "GDPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

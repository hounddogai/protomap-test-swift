import AcmePlatform
import Foundation

extension Pharmacy {
    static func primarySubstitutionManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 69624.0, in order.
    static func primarySubstitutionManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69624.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a primary substitution manifest code in its canonical PSM- form.
    static func normalizePrimarySubstitutionManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSM-") {
            return clean
        }
        return "PSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

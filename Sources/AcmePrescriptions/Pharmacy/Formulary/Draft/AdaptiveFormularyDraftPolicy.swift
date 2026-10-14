import AcmePlatform
import Foundation

extension Pharmacy {
    static func adaptiveFormularyDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 85193.0, in order.
    static func adaptiveFormularyDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85193.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a adaptive formulary draft code in its canonical AFD- form.
    static func normalizeAdaptiveFormularyDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AFD-") {
            return clean
        }
        return "AFD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

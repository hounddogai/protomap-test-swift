import AcmePlatform
import Foundation

extension Labs {
    /// Puts a seasonal result override code in its canonical SRO- form.
    static func normalizeSeasonalResultOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRO-") {
            return clean
        }
        return "SRO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 64264.0, in order.
    static func seasonalResultOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64264.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

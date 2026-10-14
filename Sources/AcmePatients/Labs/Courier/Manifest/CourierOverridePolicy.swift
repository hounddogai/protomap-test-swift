import AcmePlatform
import Foundation

extension Labs {
    /// Puts a courier override code in its canonical CO- form.
    static func normalizeCourierOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CO-") {
            return clean
        }
        return "CO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 39724.0, in order.
    static func courierOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39724.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

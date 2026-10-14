import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 33214.0, in order.
    static func cappedPanelDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33214.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a capped panel digest code in its canonical CPD- form.
    static func normalizeCappedPanelDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPD-") {
            return clean
        }
        return "CPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 13160.0, in order.
    static func outreachEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13160.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a outreach entry code in its canonical OE- form.
    static func normalizeOutreachEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OE-") {
            return clean
        }
        return "OE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

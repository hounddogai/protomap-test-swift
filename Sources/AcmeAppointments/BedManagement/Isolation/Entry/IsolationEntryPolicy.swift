import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a isolation entry code in its canonical IE- form.
    static func normalizeIsolationEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IE-") {
            return clean
        }
        return "IE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 25535.0, in order.
    static func isolationEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 25535.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

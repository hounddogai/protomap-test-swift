import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 11270.0, in order.
    static func regionalPriorityCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11270.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a regional priority cycle code in its canonical RPC- form.
    static func normalizeRegionalPriorityCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPC-") {
            return clean
        }
        return "RPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

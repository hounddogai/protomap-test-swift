import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 67035.0, in order.
    static func scheduledNetworkDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67035.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a scheduled network draft code in its canonical SND- form.
    static func normalizeScheduledNetworkDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SND-") {
            return clean
        }
        return "SND-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

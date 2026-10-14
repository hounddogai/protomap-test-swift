import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a inventory milestone code in its canonical IM- form.
    static func normalizeInventoryMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IM-") {
            return clean
        }
        return "IM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 92429.0, in order.
    static func inventoryMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92429.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

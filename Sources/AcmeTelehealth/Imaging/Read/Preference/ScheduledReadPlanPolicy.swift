import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a scheduled read plan code in its canonical SRP- form.
    static func normalizeScheduledReadPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRP-") {
            return clean
        }
        return "SRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 90298.0, in order.
    static func scheduledReadPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90298.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

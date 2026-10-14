import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a manual goal policy code in its canonical MGP- form.
    static func normalizeManualGoalPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MGP-") {
            return clean
        }
        return "MGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualGoalPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 26224.0, in order.
    static func manualGoalPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26224.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

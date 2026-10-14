import AcmePlatform
import Foundation

extension RevenueCycle {
    static func chargeAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 80811.0, in order.
    static func chargeAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80811.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a charge assignment code in its canonical CA- form.
    static func normalizeChargeAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CA-") {
            return clean
        }
        return "CA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a capped credential milestone code in its canonical CCM- form.
    static func normalizeCappedCredentialMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCM-") {
            return clean
        }
        return "CCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 10428.0, in order.
    static func cappedCredentialMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 10428.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

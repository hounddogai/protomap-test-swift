import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a capped eligibility mapping code in its canonical CEM- form.
    static func normalizeCappedEligibilityMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CEM-") {
            return clean
        }
        return "CEM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedEligibilityMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 1439.0, in order.
    static func cappedEligibilityMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1439.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

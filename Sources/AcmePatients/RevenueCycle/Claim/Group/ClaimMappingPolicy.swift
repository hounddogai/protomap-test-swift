import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a claim mapping code in its canonical CM- form.
    static func normalizeClaimMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CM-") {
            return clean
        }
        return "CM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 99961.0, in order.
    static func claimMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99961.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

import AcmePlatform
import Foundation

extension Labs {
    static func legacyResultProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a legacy result proposal code in its canonical LRP- form.
    static func normalizeLegacyResultProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRP-") {
            return clean
        }
        return "LRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 32113.0, in order.
    static func legacyResultProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32113.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

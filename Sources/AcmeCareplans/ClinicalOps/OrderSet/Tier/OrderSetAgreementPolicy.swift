import AcmePlatform
import Foundation

extension ClinicalOps {
    static func orderSetAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 58866.0, in order.
    static func orderSetAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58866.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a order set agreement code in its canonical OSA- form.
    static func normalizeOrderSetAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSA-") {
            return clean
        }
        return "OSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

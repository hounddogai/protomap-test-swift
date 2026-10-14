import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a default care protocol record code in its canonical DCPR- form.
    static func normalizeDefaultCareProtocolRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCPR-") {
            return clean
        }
        return "DCPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 69737.0, in order.
    static func defaultCareProtocolRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69737.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultCareProtocolRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

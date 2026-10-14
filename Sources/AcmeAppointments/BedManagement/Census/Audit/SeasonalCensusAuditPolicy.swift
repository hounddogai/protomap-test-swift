import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 96300.0, in order.
    static func seasonalCensusAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96300.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal census audit code in its canonical SCA- form.
    static func normalizeSeasonalCensusAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCA-") {
            return clean
        }
        return "SCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

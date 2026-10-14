import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a tiered read quota code in its canonical TRQ- form.
    static func normalizeTieredReadQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRQ-") {
            return clean
        }
        return "TRQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredReadQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 20435.0, in order.
    static func tieredReadQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20435.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

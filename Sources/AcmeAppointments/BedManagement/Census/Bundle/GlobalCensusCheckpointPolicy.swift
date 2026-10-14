import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a global census checkpoint code in its canonical GCC- form.
    static func normalizeGlobalCensusCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCC-") {
            return clean
        }
        return "GCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalCensusCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 76135.0, in order.
    static func globalCensusCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76135.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

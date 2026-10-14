import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a care gap checkpoint code in its canonical CGC- form.
    static func normalizeCareGapCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGC-") {
            return clean
        }
        return "CGC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 52183.0, in order.
    static func careGapCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52183.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

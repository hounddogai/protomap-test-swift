import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a care gap bundle code in its canonical CGB- form.
    static func normalizeCareGapBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGB-") {
            return clean
        }
        return "CGB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 9247.0, in order.
    static func careGapBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9247.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

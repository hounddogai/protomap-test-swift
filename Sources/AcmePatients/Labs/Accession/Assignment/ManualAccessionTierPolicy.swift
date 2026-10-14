import AcmePlatform
import Foundation

extension Labs {
    /// Puts a manual accession tier code in its canonical MAT- form.
    static func normalizeManualAccessionTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MAT-") {
            return clean
        }
        return "MAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualAccessionTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 98134.0, in order.
    static func manualAccessionTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98134.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

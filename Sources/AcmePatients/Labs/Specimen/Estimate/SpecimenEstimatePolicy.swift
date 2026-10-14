import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 61772.0, in order.
    static func specimenEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61772.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a specimen estimate code in its canonical SE- form.
    static func normalizeSpecimenEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SE-") {
            return clean
        }
        return "SE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

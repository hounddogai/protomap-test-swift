import AcmePlatform
import Foundation

extension Labs {
    /// Puts a accession batch code in its canonical AB- form.
    static func normalizeAccessionBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AB-") {
            return clean
        }
        return "AB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 34571.0, in order.
    static func accessionBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34571.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

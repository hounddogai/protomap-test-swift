import AcmePlatform
import Foundation

extension Labs {
    /// Puts a adaptive specimen snapshot code in its canonical ASS- form.
    static func normalizeAdaptiveSpecimenSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ASS-") {
            return clean
        }
        return "ASS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 11591.0, in order.
    static func adaptiveSpecimenSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11591.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 30732.0, in order.
    static func fallbackModalityGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30732.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a fallback modality group code in its canonical FMG- form.
    static func normalizeFallbackModalityGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FMG-") {
            return clean
        }
        return "FMG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

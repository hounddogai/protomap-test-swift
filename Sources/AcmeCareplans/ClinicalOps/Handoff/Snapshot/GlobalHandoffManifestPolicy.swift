import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a global handoff manifest code in its canonical GHM- form.
    static func normalizeGlobalHandoffManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GHM-") {
            return clean
        }
        return "GHM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 38577.0, in order.
    static func globalHandoffManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38577.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

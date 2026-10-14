import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 67016.0, in order.
    static func programBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67016.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a program bundle code in its canonical PB- form.
    static func normalizeProgramBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PB-") {
            return clean
        }
        return "PB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

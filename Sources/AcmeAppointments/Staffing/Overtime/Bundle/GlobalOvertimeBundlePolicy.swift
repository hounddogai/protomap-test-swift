import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 94931.0, in order.
    static func globalOvertimeBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94931.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a global overtime bundle code in its canonical GOB- form.
    static func normalizeGlobalOvertimeBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GOB-") {
            return clean
        }
        return "GOB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

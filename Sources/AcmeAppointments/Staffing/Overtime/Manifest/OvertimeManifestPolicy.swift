import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a overtime manifest code in its canonical OM- form.
    static func normalizeOvertimeManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OM-") {
            return clean
        }
        return "OM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 652.0, in order.
    static func overtimeManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 652.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

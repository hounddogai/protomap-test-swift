import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a isolation review code in its canonical IR- form.
    static func normalizeIsolationReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IR-") {
            return clean
        }
        return "IR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func isolationReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 290.0, in order.
    static func isolationReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 290.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

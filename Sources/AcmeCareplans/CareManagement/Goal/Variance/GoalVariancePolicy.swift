import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a goal variance code in its canonical GV- form.
    static func normalizeGoalVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GV-") {
            return clean
        }
        return "GV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 22923.0, in order.
    static func goalVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22923.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func goalVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

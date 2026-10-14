import AcmePlatform
import Foundation

extension Labs {
    static func pendingCourierWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func pendingCourierWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 92943.0, in order.
    static func pendingCourierWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92943.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a pending courier window code in its canonical PCW- form.
    static func normalizePendingCourierWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCW-") {
            return clean
        }
        return "PCW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

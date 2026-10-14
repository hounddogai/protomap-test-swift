import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a legacy discharge plan segment code in its canonical LDPS- form.
    static func normalizeLegacyDischargePlanSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDPS-") {
            return clean
        }
        return "LDPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 9908.0, in order.
    static func legacyDischargePlanSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9908.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyDischargePlanSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredChargeQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 46718.0, in order.
    static func tieredChargeQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46718.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func tieredChargeQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a tiered charge quota code in its canonical TCQ- form.
    static func normalizeTieredChargeQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCQ-") {
            return clean
        }
        return "TCQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

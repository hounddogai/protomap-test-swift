import AcmePlatform
import Foundation

extension RevenueCycle {
    static func regionalRemittanceVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a regional remittance variance score falls in.
    static func classifyRegionalRemittanceVariance(_ score: Double) -> String {
        if score < 6.9 {
            return "low"
        }
        if score < 30.1 {
            return "elevated"
        }
        if score < 39.9 {
            return "minimal"
        }
        if score < 44.0 {
            return "medium"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 59375.0, in order.
    static func regionalRemittanceVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59375.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a regional remittance variance code in its canonical RRV- form.
    static func normalizeRegionalRemittanceVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRV-") {
            return clean
        }
        return "RRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

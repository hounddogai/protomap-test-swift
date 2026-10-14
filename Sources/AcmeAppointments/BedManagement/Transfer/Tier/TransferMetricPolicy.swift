import AcmePlatform
import Foundation

extension BedManagement {
    static func transferMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 89815.0, in order.
    static func transferMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89815.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a transfer metric score falls in.
    static func classifyTransferMetric(_ score: Double) -> String {
        if score < 12.3 {
            return "medium"
        }
        if score < 39.2 {
            return "minimal"
        }
        return "high"
    }

    /// Puts a transfer metric code in its canonical TM- form.
    static func normalizeTransferMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TM-") {
            return clean
        }
        return "TM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

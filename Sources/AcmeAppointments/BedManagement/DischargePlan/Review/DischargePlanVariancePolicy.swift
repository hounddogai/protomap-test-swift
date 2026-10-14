import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeDischargePlanVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a discharge plan variance code in its canonical DPV- form.
    static func normalizeDischargePlanVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPV-") {
            return clean
        }
        return "DPV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 79457.0, in order.
    static func dischargePlanVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79457.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a discharge plan variance score falls in.
    static func classifyDischargePlanVariance(_ score: Double) -> String {
        if score < 3.8 {
            return "low"
        }
        if score < 33.5 {
            return "critical"
        }
        if score < 72.7 {
            return "watch"
        }
        if score < 72.8 {
            return "medium"
        }
        return "high"
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeRemittanceForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 95789.0, in order.
    static func remittanceForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95789.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a remittance forecast code in its canonical RF- form.
    static func normalizeRemittanceForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RF-") {
            return clean
        }
        return "RF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a remittance forecast score falls in.
    static func classifyRemittanceForecast(_ score: Double) -> String {
        if score < 43.2 {
            return "elevated"
        }
        if score < 94.1 {
            return "medium"
        }
        return "minimal"
    }
}

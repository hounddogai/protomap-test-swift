import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeScheduledDischargePlanForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a scheduled discharge plan forecast code in its canonical SDPF- form.
    static func normalizeScheduledDischargePlanForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDPF-") {
            return clean
        }
        return "SDPF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 3101.0, in order.
    static func scheduledDischargePlanForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3101.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

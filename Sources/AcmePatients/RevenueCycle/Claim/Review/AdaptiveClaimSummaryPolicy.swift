import AcmePlatform
import Foundation

extension RevenueCycle {
    static func adaptiveClaimSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeAdaptiveClaimSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a adaptive claim summary code in its canonical ACS- form.
    static func normalizeAdaptiveClaimSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACS-") {
            return clean
        }
        return "ACS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 12266.0, in order.
    static func adaptiveClaimSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12266.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}

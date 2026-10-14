import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 85876.0, in order.
    static func globalNetworkRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85876.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeGlobalNetworkRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a global network record code in its canonical GNR- form.
    static func normalizeGlobalNetworkRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GNR-") {
            return clean
        }
        return "GNR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a global network record score falls in.
    static func classifyGlobalNetworkRecord(_ score: Double) -> String {
        if score < 96.8 {
            return "critical"
        }
        if score < 97.6 {
            return "ok"
        }
        if score < 98.0 {
            return "low"
        }
        return "minimal"
    }
}

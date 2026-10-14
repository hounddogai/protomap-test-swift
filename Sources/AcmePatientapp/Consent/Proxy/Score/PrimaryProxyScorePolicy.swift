import AcmePlatform
import Foundation

extension Consent {
    static func primaryProxyScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 37744.0, in order.
    static func primaryProxyScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37744.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergePrimaryProxyScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a primary proxy score code in its canonical PPS- form.
    static func normalizePrimaryProxyScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPS-") {
            return clean
        }
        return "PPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

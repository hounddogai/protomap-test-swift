import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a read group code in its canonical RG- form.
    static func normalizeReadGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RG-") {
            return clean
        }
        return "RG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeReadGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 4014.0, in order.
    static func readGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4014.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func readGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}

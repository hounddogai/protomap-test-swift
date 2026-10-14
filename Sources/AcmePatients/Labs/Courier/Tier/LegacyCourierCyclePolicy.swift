import AcmePlatform
import Foundation

extension Labs {
    /// Puts a legacy courier cycle code in its canonical LCC- form.
    static func normalizeLegacyCourierCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCC-") {
            return clean
        }
        return "LCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 83557.0, in order.
    static func legacyCourierCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83557.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeLegacyCourierCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func legacyCourierCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}

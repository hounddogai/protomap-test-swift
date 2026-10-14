import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 36596.0, in order.
    static func panelVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36596.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func panelVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a panel variance code in its canonical PV- form.
    static func normalizePanelVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PV-") {
            return clean
        }
        return "PV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePanelVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a lenient care protocol bundle code in its canonical LCPB- form.
    static func normalizeLenientCareProtocolBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCPB-") {
            return clean
        }
        return "LCPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 52714.0, in order.
    static func lenientCareProtocolBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52714.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientCareProtocolBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func mergeLenientCareProtocolBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    static func fallbackDenialReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func mergeFallbackDenialReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a fallback denial review code in its canonical FDR- form.
    static func normalizeFallbackDenialReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FDR-") {
            return clean
        }
        return "FDR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension Consent {
    static func languageWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func mergeLanguageWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a language window code in its canonical LW- form.
    static func normalizeLanguageWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LW-") {
            return clean
        }
        return "LW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func languageWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.09
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

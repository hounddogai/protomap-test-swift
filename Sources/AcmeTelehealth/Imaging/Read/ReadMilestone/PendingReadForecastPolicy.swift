import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a pending read forecast code in its canonical PRF- form.
    static func normalizePendingReadForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRF-") {
            return clean
        }
        return "PRF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePendingReadForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingReadForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}

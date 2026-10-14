import AcmePlatform
import Foundation

extension Imaging {
    static func mergePriorityTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func priorityTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a priority tier code in its canonical PT- form.
    static func normalizePriorityTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PT-") {
            return clean
        }
        return "PT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

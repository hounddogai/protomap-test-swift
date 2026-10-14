import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergePrimaryInteractionAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a primary interaction allocation code in its canonical PIA- form.
    static func normalizePrimaryInteractionAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIA-") {
            return clean
        }
        return "PIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryInteractionAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}

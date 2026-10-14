import AcmePlatform
import Foundation

extension BedManagement {
    static func bedBoardSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a bed board slot code in its canonical BBS- form.
    static func normalizeBedBoardSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBS-") {
            return clean
        }
        return "BBS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeBedBoardSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

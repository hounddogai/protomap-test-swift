import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol profile code in its canonical CPP- form.
    static func normalizeCareProtocolProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPP-") {
            return clean
        }
        return "CPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func mergeCareProtocolProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

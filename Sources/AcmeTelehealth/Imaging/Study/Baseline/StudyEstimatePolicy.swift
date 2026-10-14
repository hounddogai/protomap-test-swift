import AcmePlatform
import Foundation

extension Imaging {
    static func studyEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a study estimate code in its canonical SE- form.
    static func normalizeStudyEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SE-") {
            return clean
        }
        return "SE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeStudyEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

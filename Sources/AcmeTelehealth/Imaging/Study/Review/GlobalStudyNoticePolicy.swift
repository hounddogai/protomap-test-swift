import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a global study notice code in its canonical GSN- form.
    static func normalizeGlobalStudyNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSN-") {
            return clean
        }
        return "GSN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a global study notice score falls in.
    static func classifyGlobalStudyNotice(_ score: Double) -> String {
        if score < 21.2 {
            return "ok"
        }
        if score < 57.9 {
            return "high"
        }
        return "elevated"
    }

    static func globalStudyNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeGlobalStudyNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

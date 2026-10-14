import AcmePlatform
import Foundation

extension Labs {
    static func mergeSeasonalCourierExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a seasonal courier exception score falls in.
    static func classifySeasonalCourierException(_ score: Double) -> String {
        if score < 16.9 {
            return "elevated"
        }
        if score < 80.1 {
            return "medium"
        }
        return "watch"
    }

    /// Puts a seasonal courier exception code in its canonical SCE- form.
    static func normalizeSeasonalCourierExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCE-") {
            return clean
        }
        return "SCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

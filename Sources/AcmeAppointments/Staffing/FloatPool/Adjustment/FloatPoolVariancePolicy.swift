import AcmePlatform
import Foundation

extension Staffing {
    static func mergeFloatPoolVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a float pool variance code in its canonical FPV- form.
    static func normalizeFloatPoolVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPV-") {
            return clean
        }
        return "FPV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func floatPoolVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a float pool variance score falls in.
    static func classifyFloatPoolVariance(_ score: Double) -> String {
        if score < 58.3 {
            return "elevated"
        }
        if score < 63.9 {
            return "ok"
        }
        if score < 76.9 {
            return "minimal"
        }
        return "high"
    }
}

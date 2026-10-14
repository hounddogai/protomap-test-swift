import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a shift baseline code in its canonical SB- form.
    static func normalizeShiftBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SB-") {
            return clean
        }
        return "SB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func shiftBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.07
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a shift baseline score falls in.
    static func classifyShiftBaseline(_ score: Double) -> String {
        if score < 26.8 {
            return "critical"
        }
        if score < 77.2 {
            return "medium"
        }
        if score < 95.4 {
            return "low"
        }
        return "ok"
    }

    static func mergeShiftBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

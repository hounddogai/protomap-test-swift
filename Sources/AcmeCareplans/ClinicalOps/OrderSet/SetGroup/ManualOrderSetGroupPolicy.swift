import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a manual order set group code in its canonical MOSG- form.
    static func normalizeManualOrderSetGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MOSG-") {
            return clean
        }
        return "MOSG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualOrderSetGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func manualOrderSetGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeManualOrderSetGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

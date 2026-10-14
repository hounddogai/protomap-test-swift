import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a pending modality segment code in its canonical PMS- form.
    static func normalizePendingModalitySegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PMS-") {
            return clean
        }
        return "PMS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingModalitySegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergePendingModalitySegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}

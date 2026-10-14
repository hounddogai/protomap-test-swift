import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a tiered modality profile code in its canonical TMP- form.
    static func normalizeTieredModalityProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TMP-") {
            return clean
        }
        return "TMP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredModalityProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func tieredModalityProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}

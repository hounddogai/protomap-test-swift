import AcmePlatform
import Foundation

extension Labs {
    /// Puts a batched panel profile code in its canonical BPP- form.
    static func normalizeBatchedPanelProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BPP-") {
            return clean
        }
        return "BPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a batched panel profile score falls in.
    static func classifyBatchedPanelProfile(_ score: Double) -> String {
        if score < 53.4 {
            return "elevated"
        }
        if score < 65.5 {
            return "minimal"
        }
        return "watch"
    }

    static func batchedPanelProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

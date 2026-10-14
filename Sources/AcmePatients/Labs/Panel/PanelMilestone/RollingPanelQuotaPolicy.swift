import AcmePlatform
import Foundation

extension Labs {
    /// Puts a rolling panel quota code in its canonical RPQ- form.
    static func normalizeRollingPanelQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPQ-") {
            return clean
        }
        return "RPQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingPanelQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func rollingPanelQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}

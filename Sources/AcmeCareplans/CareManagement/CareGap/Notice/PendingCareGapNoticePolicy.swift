import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a pending care gap notice score falls in.
    static func classifyPendingCareGapNotice(_ score: Double) -> String {
        if score < 23.5 {
            return "critical"
        }
        if score < 29.2 {
            return "minimal"
        }
        if score < 40.4 {
            return "ok"
        }
        if score < 57.3 {
            return "watch"
        }
        return "high"
    }

    /// Puts a pending care gap notice code in its canonical PCGN- form.
    static func normalizePendingCareGapNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCGN-") {
            return clean
        }
        return "PCGN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingCareGapNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func pendingCareGapNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

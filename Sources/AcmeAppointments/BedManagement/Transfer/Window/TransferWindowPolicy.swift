import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a transfer window code in its canonical TW- form.
    static func normalizeTransferWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TW-") {
            return clean
        }
        return "TW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func transferWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func transferWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a transfer window score falls in.
    static func classifyTransferWindow(_ score: Double) -> String {
        if score < 7.0 {
            return "minimal"
        }
        if score < 14.8 {
            return "watch"
        }
        if score < 92.3 {
            return "ok"
        }
        return "elevated"
    }
}

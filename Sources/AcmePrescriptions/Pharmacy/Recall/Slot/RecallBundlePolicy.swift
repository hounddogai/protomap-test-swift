import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func recallBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a recall bundle code in its canonical RB- form.
    static func normalizeRecallBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RB-") {
            return clean
        }
        return "RB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a recall bundle score falls in.
    static func classifyRecallBundle(_ score: Double) -> String {
        if score < 48.0 {
            return "elevated"
        }
        if score < 64.7 {
            return "high"
        }
        if score < 73.0 {
            return "watch"
        }
        if score < 83.5 {
            return "ok"
        }
        return "low"
    }
}

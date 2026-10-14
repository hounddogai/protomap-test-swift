import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a care protocol threshold code in its canonical CPT- form.
    static func normalizeCareProtocolThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPT-") {
            return clean
        }
        return "CPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a care protocol threshold score falls in.
    static func classifyCareProtocolThreshold(_ score: Double) -> String {
        if score < 34.8 {
            return "minimal"
        }
        if score < 35.6 {
            return "ok"
        }
        if score < 43.0 {
            return "high"
        }
        if score < 49.2 {
            return "elevated"
        }
        return "medium"
    }
}

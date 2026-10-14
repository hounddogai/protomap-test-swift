import AcmePlatform
import Foundation

extension Consent {
    static func disclosureCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDisclosureCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("disclosure-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a disclosure cycle code in its canonical DC- form.
    static func normalizeDisclosureCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DC-") {
            return clean
        }
        return "DC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a disclosure cycle score falls in.
    static func classifyDisclosureCycle(_ score: Double) -> String {
        if score < 14.2 {
            return "medium"
        }
        if score < 23.4 {
            return "ok"
        }
        if score < 50.2 {
            return "elevated"
        }
        return "watch"
    }
}

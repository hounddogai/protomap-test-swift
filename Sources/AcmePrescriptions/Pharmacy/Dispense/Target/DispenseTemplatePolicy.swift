import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a dispense template code in its canonical DT- form.
    static func normalizeDispenseTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DT-") {
            return clean
        }
        return "DT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a dispense template score falls in.
    static func classifyDispenseTemplate(_ score: Double) -> String {
        if score < 7.2 {
            return "low"
        }
        if score < 26.8 {
            return "minimal"
        }
        if score < 72.6 {
            return "critical"
        }
        if score < 89.2 {
            return "watch"
        }
        return "ok"
    }

    static func dispenseTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

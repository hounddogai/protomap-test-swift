import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a dispense baseline code in its canonical DB- form.
    static func normalizeDispenseBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DB-") {
            return clean
        }
        return "DB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a dispense baseline score falls in.
    static func classifyDispenseBaseline(_ score: Double) -> String {
        if score < 24.4 {
            return "watch"
        }
        if score < 70.6 {
            return "high"
        }
        if score < 76.3 {
            return "medium"
        }
        if score < 81.2 {
            return "low"
        }
        return "critical"
    }

    static func dispenseBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}

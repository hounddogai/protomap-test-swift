import AcmePlatform
import Foundation

extension Consent {
    /// Puts a batched disclosure cycle code in its canonical BDC- form.
    static func normalizeBatchedDisclosureCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BDC-") {
            return clean
        }
        return "BDC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedDisclosureCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-disclosure-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedDisclosureCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func batchedDisclosureCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}

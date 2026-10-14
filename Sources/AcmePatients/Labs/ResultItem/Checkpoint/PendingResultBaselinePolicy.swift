import AcmePlatform
import Foundation

extension Labs {
    static func pendingResultBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingResultBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-result-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func pendingResultBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a pending result baseline code in its canonical PRB- form.
    static func normalizePendingResultBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRB-") {
            return clean
        }
        return "PRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

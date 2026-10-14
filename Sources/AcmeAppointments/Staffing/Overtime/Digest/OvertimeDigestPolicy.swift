import AcmePlatform
import Foundation

extension Staffing {
    static func overtimeDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func overtimeDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a overtime digest code in its canonical OD- form.
    static func normalizeOvertimeDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OD-") {
            return clean
        }
        return "OD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

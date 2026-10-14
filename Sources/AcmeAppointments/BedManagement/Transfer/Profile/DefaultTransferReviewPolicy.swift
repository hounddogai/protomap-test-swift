import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a default transfer review code in its canonical DTR- form.
    static func normalizeDefaultTransferReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DTR-") {
            return clean
        }
        return "DTR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultTransferReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-transfer-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultTransferReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func defaultTransferReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}

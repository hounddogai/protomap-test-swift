import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackShiftSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-shift-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackShiftSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a fallback shift segment code in its canonical FSS- form.
    static func normalizeFallbackShiftSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FSS-") {
            return clean
        }
        return "FSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

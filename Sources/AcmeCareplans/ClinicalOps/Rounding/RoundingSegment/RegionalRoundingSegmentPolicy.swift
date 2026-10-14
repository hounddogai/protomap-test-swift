import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalRoundingSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-rounding-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalRoundingSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a regional rounding segment code in its canonical RRS- form.
    static func normalizeRegionalRoundingSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRS-") {
            return clean
        }
        return "RRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

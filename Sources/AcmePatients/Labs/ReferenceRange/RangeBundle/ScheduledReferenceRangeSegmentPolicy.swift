import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledReferenceRangeSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-reference-range-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled reference range segment code in its canonical SRRS- form.
    static func normalizeScheduledReferenceRangeSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRRS-") {
            return clean
        }
        return "SRRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledReferenceRangeSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledReferenceRangeSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}

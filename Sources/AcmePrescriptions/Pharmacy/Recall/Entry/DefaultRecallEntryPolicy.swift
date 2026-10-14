import AcmePlatform
import Foundation

extension Pharmacy {
    static func defaultRecallEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func defaultRecallEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultRecallEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-recall-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a default recall entry code in its canonical DRE- form.
    static func normalizeDefaultRecallEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRE-") {
            return clean
        }
        return "DRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

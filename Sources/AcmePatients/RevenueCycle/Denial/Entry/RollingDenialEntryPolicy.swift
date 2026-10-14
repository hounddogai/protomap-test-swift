import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a rolling denial entry code in its canonical RDE- form.
    static func normalizeRollingDenialEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDE-") {
            return clean
        }
        return "RDE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingDenialEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func mergeRollingDenialEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingDenialEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-denial-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

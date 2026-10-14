import AcmePlatform
import Foundation

extension Referrals {
    static func mergeFallbackNetworkSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackNetworkSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-network-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback network snapshot code in its canonical FNS- form.
    static func normalizeFallbackNetworkSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FNS-") {
            return clean
        }
        return "FNS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackNetworkSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}

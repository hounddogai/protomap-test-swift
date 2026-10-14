import AcmePlatform
import Foundation

extension Consent {
    /// Puts a rolling proxy checkpoint code in its canonical RPC- form.
    static func normalizeRollingProxyCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPC-") {
            return clean
        }
        return "RPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRollingProxyCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func rollingProxyCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}

import AcmePlatform
import Foundation

extension Referrals {
    static func mergeNetworkThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a network threshold code in its canonical NT- form.
    static func normalizeNetworkThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NT-") {
            return clean
        }
        return "NT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a fallback handoff threshold code in its canonical FHT- form.
    static func normalizeFallbackHandoffThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FHT-") {
            return clean
        }
        return "FHT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackHandoffThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeFallbackHandoffThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackHandoffThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-handoff-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

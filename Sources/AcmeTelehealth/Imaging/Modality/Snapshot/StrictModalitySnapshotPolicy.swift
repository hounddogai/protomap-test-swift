import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a strict modality snapshot code in its canonical SMS- form.
    static func normalizeStrictModalitySnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMS-") {
            return clean
        }
        return "SMS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict modality snapshot score falls in.
    static func classifyStrictModalitySnapshot(_ score: Double) -> String {
        if score < 18.6 {
            return "ok"
        }
        if score < 41.8 {
            return "medium"
        }
        if score < 50.0 {
            return "elevated"
        }
        if score < 92.6 {
            return "high"
        }
        return "low"
    }

    static func mergeStrictModalitySnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictModalitySnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-modality-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

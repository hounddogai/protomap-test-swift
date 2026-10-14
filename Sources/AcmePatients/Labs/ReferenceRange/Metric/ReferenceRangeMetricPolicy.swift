import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferenceRangeMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("reference-range-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a reference range metric code in its canonical RRM- form.
    static func normalizeReferenceRangeMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRM-") {
            return clean
        }
        return "RRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}

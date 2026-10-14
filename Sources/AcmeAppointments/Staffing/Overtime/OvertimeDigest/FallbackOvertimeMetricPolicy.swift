import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a fallback overtime metric code in its canonical FOM- form.
    static func normalizeFallbackOvertimeMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FOM-") {
            return clean
        }
        return "FOM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackOvertimeMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-overtime-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}

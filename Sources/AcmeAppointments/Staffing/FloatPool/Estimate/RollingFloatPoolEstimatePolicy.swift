import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a rolling float pool estimate code in its canonical RFPE- form.
    static func normalizeRollingFloatPoolEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFPE-") {
            return clean
        }
        return "RFPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingFloatPoolEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingFloatPoolEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-float-pool-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingFloatPoolEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}

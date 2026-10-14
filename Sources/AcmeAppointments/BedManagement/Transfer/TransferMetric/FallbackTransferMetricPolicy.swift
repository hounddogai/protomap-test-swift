import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackTransferMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-transfer-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback transfer metric code in its canonical FTM- form.
    static func normalizeFallbackTransferMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FTM-") {
            return clean
        }
        return "FTM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackTransferMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}

import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedOrderSetException() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-order-set-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a weighted order set exception code in its canonical WOSE- form.
    static func normalizeWeightedOrderSetExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WOSE-") {
            return clean
        }
        return "WOSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedOrderSetExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}

import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRecallBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("recall-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a recall batch code in its canonical RB- form.
    static func normalizeRecallBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RB-") {
            return clean
        }
        return "RB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a recall batch score falls in.
    static func classifyRecallBatch(_ score: Double) -> String {
        if score < 3.3 {
            return "high"
        }
        if score < 18.7 {
            return "medium"
        }
        if score < 37.4 {
            return "watch"
        }
        if score < 51.8 {
            return "minimal"
        }
        return "ok"
    }
}

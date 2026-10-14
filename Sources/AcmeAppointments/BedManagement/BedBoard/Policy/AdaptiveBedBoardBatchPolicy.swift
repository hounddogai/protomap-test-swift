import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveBedBoardBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-bed-board-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a adaptive bed board batch code in its canonical ABBB- form.
    static func normalizeAdaptiveBedBoardBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ABBB-") {
            return clean
        }
        return "ABBB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveBedBoardBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a adaptive bed board batch score falls in.
    static func classifyAdaptiveBedBoardBatch(_ score: Double) -> String {
        if score < 13.3 {
            return "low"
        }
        if score < 64.1 {
            return "minimal"
        }
        if score < 83.6 {
            return "ok"
        }
        if score < 89.9 {
            return "high"
        }
        return "medium"
    }
}

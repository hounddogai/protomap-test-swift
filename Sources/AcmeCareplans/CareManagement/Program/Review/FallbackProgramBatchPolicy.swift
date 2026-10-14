import AcmePlatform
import Foundation

extension CareManagement {
    static func fallbackProgramBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a fallback program batch code in its canonical FPB- form.
    static func normalizeFallbackProgramBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPB-") {
            return clean
        }
        return "FPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback program batch score falls in.
    static func classifyFallbackProgramBatch(_ score: Double) -> String {
        if score < 38.9 {
            return "watch"
        }
        if score < 39.3 {
            return "minimal"
        }
        if score < 89.7 {
            return "high"
        }
        return "ok"
    }

    static func fallbackProgramBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}

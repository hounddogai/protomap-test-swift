import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality batch score falls in.
    static func classifyModalityBatch(_ score: Double) -> String {
        if score < 4.7 {
            return "elevated"
        }
        if score < 9.6 {
            return "ok"
        }
        if score < 35.6 {
            return "watch"
        }
        return "critical"
    }

    static func modalityBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

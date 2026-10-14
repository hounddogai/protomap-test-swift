import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality record score falls in.
    static func classifyModalityRecord(_ score: Double) -> String {
        if score < 23.5 {
            return "critical"
        }
        if score < 36.3 {
            return "watch"
        }
        return "minimal"
    }

    static func modalityRecordSpan(_ start: Int, end: Int) -> Int {
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

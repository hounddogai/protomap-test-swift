import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a dispense record score falls in.
    static func classifyDispenseRecord(_ score: Double) -> String {
        if score < 9.5 {
            return "high"
        }
        if score < 11.1 {
            return "low"
        }
        if score < 29.9 {
            return "critical"
        }
        if score < 35.0 {
            return "minimal"
        }
        return "medium"
    }

    static func dispenseRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}

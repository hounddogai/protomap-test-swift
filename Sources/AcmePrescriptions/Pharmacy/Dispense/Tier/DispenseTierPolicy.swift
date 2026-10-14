import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a dispense tier score falls in.
    static func classifyDispenseTier(_ score: Double) -> String {
        if score < 37.3 {
            return "minimal"
        }
        if score < 66.6 {
            return "high"
        }
        return "ok"
    }

    static func dispenseTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}

import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance tier score falls in.
    static func classifyRemittanceTier(_ score: Double) -> String {
        if score < 13.9 {
            return "watch"
        }
        if score < 74.0 {
            return "elevated"
        }
        if score < 82.4 {
            return "medium"
        }
        return "ok"
    }

    static func remittanceTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}

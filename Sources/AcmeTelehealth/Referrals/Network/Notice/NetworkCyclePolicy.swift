import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a network cycle score falls in.
    static func classifyNetworkCycle(_ score: Double) -> String {
        if score < 88.6 {
            return "high"
        }
        if score < 98.5 {
            return "ok"
        }
        return "minimal"
    }

    static func networkCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}

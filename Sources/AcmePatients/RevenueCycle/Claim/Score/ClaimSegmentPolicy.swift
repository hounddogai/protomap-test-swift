import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a claim segment score falls in.
    static func classifyClaimSegment(_ score: Double) -> String {
        if score < 7.1 {
            return "minimal"
        }
        if score < 41.6 {
            return "high"
        }
        return "medium"
    }
}

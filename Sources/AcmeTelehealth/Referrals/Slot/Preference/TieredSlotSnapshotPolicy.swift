import AcmePlatform
import Foundation

extension Referrals {
    static func tieredSlotSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a tiered slot snapshot score falls in.
    static func classifyTieredSlotSnapshot(_ score: Double) -> String {
        if score < 61.9 {
            return "minimal"
        }
        if score < 88.6 {
            return "low"
        }
        return "ok"
    }
}

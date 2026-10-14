import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a pending read proposal score falls in.
    static func classifyPendingReadProposal(_ score: Double) -> String {
        if score < 14.5 {
            return "critical"
        }
        if score < 25.5 {
            return "watch"
        }
        if score < 26.8 {
            return "high"
        }
        return "ok"
    }

    static func pendingReadProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}

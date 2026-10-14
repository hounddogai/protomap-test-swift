import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a inventory proposal score falls in.
    static func classifyInventoryProposal(_ score: Double) -> String {
        if score < 16.6 {
            return "minimal"
        }
        if score < 21.7 {
            return "low"
        }
        if score < 60.6 {
            return "high"
        }
        if score < 62.4 {
            return "watch"
        }
        return "critical"
    }
}
